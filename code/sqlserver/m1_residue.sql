-- m1_residue.sql  (measured run for F1, F2, F3)
-- sqlcmd variables: SCALE (rows), METHOD (DELETE or UPDATE), TRIAL, SEED
-- Fresh database per trial. Erases 100 seeded-random subjects from a CDC table and a temporal
-- table, waits until the capture job has recorded the erasure, then counts where the original
-- values are still readable. Prints one line starting with RESULT,
SET NOCOUNT ON;
GO
USE master;
GO
IF DB_ID('m_trial') IS NOT NULL
BEGIN
    IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = 'm_trial') = 1
        EXEC m_trial.sys.sp_cdc_disable_db;
    ALTER DATABASE m_trial SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE m_trial;
END
GO
CREATE DATABASE m_trial;
GO
USE m_trial;
GO
CREATE TABLE dbo.metrics (k VARCHAR(40) PRIMARY KEY, v BIGINT);
CREATE TABLE dbo.erased  (id INT PRIMARY KEY);
CREATE TABLE dbo.customer (
    customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL);
CREATE TABLE dbo.member (
    member_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    valid_to   DATETIME2 GENERATED ALWAYS AS ROW END   NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.member_history));
GO
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customer',
     @role_name = NULL, @supports_net_changes = 1;
GO
;WITH n AS (
    SELECT TOP ($(SCALE)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c
)
INSERT dbo.customer (customer_id, full_name, email, phone)
SELECT i, CONCAT('Subject_', RIGHT(CONCAT('0000000', i), 7)),
       CONCAT('subject', i, '@example.invalid'), CONCAT('+1-555-', RIGHT(CONCAT('0000000', i), 7))
FROM n;
INSERT dbo.member (member_id, full_name, email, phone)
SELECT customer_id, full_name, email, phone FROM dbo.customer;
INSERT dbo.erased (id)
SELECT TOP (100) customer_id FROM dbo.customer
ORDER BY HASHBYTES('SHA1', CONCAT(customer_id, ':', $(SEED)));
GO
-- Wait until the capture job has recorded every insert (max 10 minutes)
DECLARE @i INT = 0;
WHILE @i < 300 AND (SELECT COUNT(*) FROM cdc.dbo_customer_CT) < $(SCALE)
BEGIN
    WAITFOR DELAY '00:00:02';
    SET @i += 1;
END
INSERT dbo.metrics VALUES ('load_capture_wait_s', @i * 2);
INSERT dbo.metrics VALUES ('load_captured_rows', (SELECT COUNT(*) FROM cdc.dbo_customer_CT));
GO
-- Erasure
IF '$(METHOD)' = 'DELETE'
BEGIN
    DELETE c FROM dbo.customer c JOIN dbo.erased e ON e.id = c.customer_id;
    DELETE m FROM dbo.member   m JOIN dbo.erased e ON e.id = m.member_id;
END
ELSE
BEGIN
    UPDATE c SET full_name = 'REDACTED', email = 'redacted@example.invalid', phone = NULL
    FROM dbo.customer c JOIN dbo.erased e ON e.id = c.customer_id;
    UPDATE m SET full_name = 'REDACTED', email = 'redacted@example.invalid', phone = NULL
    FROM dbo.member m JOIN dbo.erased e ON e.id = m.member_id;
END
GO
-- Wait until the capture job has recorded the erasure of all 100 subjects (max 5 minutes)
DECLARE @i INT = 0, @op INT = CASE '$(METHOD)' WHEN 'DELETE' THEN 1 ELSE 4 END;
WHILE @i < 150 AND (SELECT COUNT(*) FROM cdc.dbo_customer_CT WHERE __$operation = @op) < 100
BEGIN
    WAITFOR DELAY '00:00:02';
    SET @i += 1;
END
INSERT dbo.metrics VALUES ('erase_capture_wait_s', @i * 2);
INSERT dbo.metrics VALUES ('erase_records_captured',
    (SELECT COUNT(*) FROM cdc.dbo_customer_CT WHERE __$operation = @op));
GO
-- Where are the original values still readable?
INSERT dbo.metrics VALUES ('src_rows_readable',
    (SELECT COUNT(*) FROM dbo.customer c JOIN dbo.erased e ON e.id = c.customer_id
      WHERE c.full_name LIKE 'Subject[_]%')
  + (SELECT COUNT(*) FROM dbo.member m JOIN dbo.erased e ON e.id = m.member_id
      WHERE m.full_name LIKE 'Subject[_]%'));
INSERT dbo.metrics VALUES ('ct_copies',
    (SELECT COUNT(*) FROM cdc.dbo_customer_CT t JOIN dbo.erased e ON e.id = t.customer_id
      WHERE t.full_name LIKE 'Subject[_]%'));
INSERT dbo.metrics VALUES ('ct_subjects',
    (SELECT COUNT(DISTINCT t.customer_id) FROM cdc.dbo_customer_CT t JOIN dbo.erased e ON e.id = t.customer_id
      WHERE t.full_name LIKE 'Subject[_]%'));
INSERT dbo.metrics VALUES ('hist_copies',
    (SELECT COUNT(*) FROM dbo.member_history h JOIN dbo.erased e ON e.id = h.member_id
      WHERE h.full_name LIKE 'Subject[_]%'));
INSERT dbo.metrics VALUES ('hist_subjects',
    (SELECT COUNT(DISTINCT h.member_id) FROM dbo.member_history h JOIN dbo.erased e ON e.id = h.member_id
      WHERE h.full_name LIKE 'Subject[_]%'));
INSERT dbo.metrics VALUES ('timetravel_subjects',
    (SELECT COUNT(DISTINCT m.member_id) FROM dbo.member FOR SYSTEM_TIME ALL AS m
       JOIN dbo.erased e ON e.id = m.member_id
      WHERE m.full_name LIKE 'Subject[_]%'));
INSERT dbo.metrics VALUES ('cdc_retention_min',
    (SELECT retention FROM msdb.dbo.cdc_jobs WHERE database_id = DB_ID() AND job_type = 'cleanup'));
INSERT dbo.metrics VALUES ('temporal_retention',
    (SELECT history_retention_period FROM sys.tables WHERE name = 'member'));
GO
SELECT CONCAT('RESULT,', $(SCALE), ',$(METHOD),', $(TRIAL), ',', $(SEED), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'load_captured_rows'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'erase_records_captured'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'src_rows_readable'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'ct_copies'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'ct_subjects'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'hist_copies'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'hist_subjects'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'timetravel_subjects'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'cdc_retention_min'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'temporal_retention'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'load_capture_wait_s'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'erase_capture_wait_s'));
GO
