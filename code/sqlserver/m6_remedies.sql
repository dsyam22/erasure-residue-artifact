-- m6_remedies.sql   (sqlcmd variable: TRIAL)
-- Measures, in a fresh database m6_lab:
--   A. copies of an erased subject when a table has two capture instances
--   B. which database principals can read each residue surface
--   C. removing ONE subject's entries from a CDC change table with a direct DELETE
--   D. removing ONE subject's rows from a temporal history table (versioning off / on)
--   E. the remedy for a dropped column: new capture instance, old one disabled
-- Every test runs through dbo.m6_try, which records 'ok:<count>' or 'error:<number>'.
-- Output lines: RESULT,<trial>,<key>,<value>.  Synthetic data only.
SET NOCOUNT ON;
GO
USE master;
GO
IF DB_ID('m6_lab') IS NOT NULL
BEGIN
    IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = 'm6_lab') = 1
        EXEC m6_lab.sys.sp_cdc_disable_db;
    ALTER DATABASE m6_lab SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE m6_lab;
END
GO
CREATE DATABASE m6_lab;
GO
USE m6_lab;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL,
                           email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL);
CREATE TABLE dbo.member (member_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    valid_to   DATETIME2 GENERATED ALWAYS AS ROW END   NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.member_history));
CREATE TABLE dbo.m6_result (seq INT IDENTITY PRIMARY KEY, k VARCHAR(80) NOT NULL, v VARCHAR(80) NOT NULL);
GO
CREATE PROCEDURE dbo.m6_try @who SYSNAME, @k VARCHAR(80), @sql NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @n INT, @r VARCHAR(80);
    IF @who IS NOT NULL EXECUTE AS USER = @who;
    BEGIN TRY
        EXEC sp_executesql @sql, N'@n INT OUTPUT', @n = @n OUTPUT;
        SET @r = CONCAT('ok:', @n);
    END TRY
    BEGIN CATCH
        SET @r = CONCAT('error:', ERROR_NUMBER());
    END CATCH
    IF @who IS NOT NULL REVERT;
    INSERT dbo.m6_result (k, v) VALUES (@k, @r);
END
GO
EXEC master.sys.sp_getapplock @Resource = 'm_setup', @LockMode = 'Exclusive',
     @LockOwner = 'Session', @LockTimeout = 900000;
GO
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customer',
     @role_name = NULL, @supports_net_changes = 1;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customer',
     @role_name = NULL, @supports_net_changes = 1, @capture_instance = N'dbo_customer_v2';
GO
EXEC master.sys.sp_releaseapplock @Resource = 'm_setup', @LockOwner = 'Session';
GO
-- principals: a reader (db_datareader), and an application user with SELECT on the two tables only
CREATE USER m6_reader WITHOUT LOGIN;
ALTER ROLE db_datareader ADD MEMBER m6_reader;
CREATE USER m6_app WITHOUT LOGIN;
GRANT SELECT ON dbo.customer TO m6_app;
GRANT SELECT ON dbo.member   TO m6_app;
GO
;WITH n AS (SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
            FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT dbo.customer (customer_id, full_name, email, phone)
SELECT i, CONCAT('Subject_', RIGHT(CONCAT('000000', i), 6)), CONCAT('subject', i, '@example.invalid'),
       CONCAT('+1-555-', RIGHT(CONCAT('0000', i), 4)) FROM n;
INSERT dbo.member (member_id, full_name, email, phone) SELECT customer_id, full_name, email, phone FROM dbo.customer;
GO
DECLARE @i INT = 0;
WHILE @i < 300 AND ((SELECT COUNT(*) FROM cdc.dbo_customer_CT) < 1000 OR (SELECT COUNT(*) FROM cdc.dbo_customer_v2_CT) < 1000)
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
GO
-- the erasure: subjects 1 to 10
DELETE FROM dbo.customer WHERE customer_id <= 10;
DELETE FROM dbo.member   WHERE member_id   <= 10;
GO
DECLARE @i INT = 0;
WHILE @i < 300 AND ((SELECT COUNT(*) FROM cdc.dbo_customer_CT WHERE __$operation = 1) < 10
                 OR (SELECT COUNT(*) FROM cdc.dbo_customer_v2_CT WHERE __$operation = 1) < 10)
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
GO

-- A. two capture instances
EXEC dbo.m6_try NULL, 'A_copies_instance1_10subjects', N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id <= 10';
EXEC dbo.m6_try NULL, 'A_copies_instance2_10subjects', N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_v2_CT WHERE customer_id <= 10';
GO

-- B. who can read each surface
EXEC dbo.m6_try 'm6_reader', 'B_reader_change_table',   N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id <= 10';
EXEC dbo.m6_try 'm6_reader', 'B_reader_cdc_function',   N'SELECT @n = COUNT(*) FROM cdc.fn_cdc_get_all_changes_dbo_customer(sys.fn_cdc_get_min_lsn(''dbo_customer''), sys.fn_cdc_get_max_lsn(), ''all'') WHERE customer_id <= 10';
EXEC dbo.m6_try 'm6_reader', 'B_reader_history_table',  N'SELECT @n = COUNT(*) FROM dbo.member_history WHERE member_id <= 10';
EXEC dbo.m6_try 'm6_reader', 'B_reader_time_travel',    N'SELECT @n = COUNT(*) FROM dbo.member FOR SYSTEM_TIME ALL WHERE member_id <= 10';
EXEC dbo.m6_try 'm6_app',    'B_app_source_table',      N'SELECT @n = COUNT(*) FROM dbo.customer';
EXEC dbo.m6_try 'm6_app',    'B_app_change_table',      N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id <= 10';
EXEC dbo.m6_try 'm6_app',    'B_app_cdc_function',      N'SELECT @n = COUNT(*) FROM cdc.fn_cdc_get_all_changes_dbo_customer(sys.fn_cdc_get_min_lsn(''dbo_customer''), sys.fn_cdc_get_max_lsn(), ''all'') WHERE customer_id <= 10';
EXEC dbo.m6_try 'm6_app',    'B_app_history_table',     N'SELECT @n = COUNT(*) FROM dbo.member_history WHERE member_id <= 10';
EXEC dbo.m6_try 'm6_app',    'B_app_time_travel',       N'SELECT @n = COUNT(*) FROM dbo.member FOR SYSTEM_TIME ALL WHERE member_id <= 10';
GO

-- C. remove one subject (id 1) from the change table with a direct DELETE, as database owner
EXEC dbo.m6_try NULL, 'C_delete_from_change_table',    N'DELETE FROM cdc.dbo_customer_CT WHERE customer_id = 1; SET @n = @@ROWCOUNT';
EXEC dbo.m6_try NULL, 'C_subject1_rows_left',          N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id = 1';
EXEC dbo.m6_try NULL, 'C_other9_rows_left',            N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id BETWEEN 2 AND 10';
EXEC dbo.m6_try NULL, 'C_rows_left_total',             N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_CT';
EXEC dbo.m6_try NULL, 'C_net_changes_still_readable',  N'SELECT @n = COUNT(*) FROM cdc.fn_cdc_get_net_changes_dbo_customer(sys.fn_cdc_get_min_lsn(''dbo_customer''), sys.fn_cdc_get_max_lsn(), ''all'')';
EXEC dbo.m6_try NULL, 'C_subject1_in_other_instance',  N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_v2_CT WHERE customer_id = 1';
GO

-- D. remove one subject (id 1) from the history table
EXEC dbo.m6_try NULL, 'D_delete_history_versioning_on', N'DELETE FROM dbo.member_history WHERE member_id = 1; SET @n = @@ROWCOUNT';
EXEC dbo.m6_try NULL, 'D_versioning_off',               N'ALTER TABLE dbo.member SET (SYSTEM_VERSIONING = OFF)';
EXEC dbo.m6_try NULL, 'D_delete_history_versioning_off', N'DELETE FROM dbo.member_history WHERE member_id = 1; SET @n = @@ROWCOUNT';
EXEC dbo.m6_try NULL, 'D_versioning_on_again',          N'ALTER TABLE dbo.member SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.member_history, DATA_CONSISTENCY_CHECK = ON))';
EXEC dbo.m6_try NULL, 'D_subject1_rows_left',           N'SELECT @n = COUNT(*) FROM dbo.member_history WHERE member_id = 1';
EXEC dbo.m6_try NULL, 'D_other9_rows_left',             N'SELECT @n = COUNT(*) FROM dbo.member_history WHERE member_id BETWEEN 2 AND 10';
EXEC dbo.m6_try NULL, 'D_table_is_temporal_again',      N'SELECT @n = temporal_type FROM sys.tables WHERE name = ''member''';
EXEC dbo.m6_try NULL, 'D_time_travel_subject1',         N'SELECT @n = COUNT(*) FROM dbo.member FOR SYSTEM_TIME ALL WHERE member_id = 1';
GO

-- E. dropped column: disable the second instance, drop the column, create a new instance,
--    disable the old one
EXEC dbo.m6_try NULL, 'E_disable_instance2',            N'EXEC sys.sp_cdc_disable_table @source_schema = N''dbo'', @source_name = N''customer'', @capture_instance = N''dbo_customer_v2''';
EXEC dbo.m6_try NULL, 'E_instance2_table_exists',       N'SELECT @n = CASE WHEN OBJECT_ID(''cdc.dbo_customer_v2_CT'') IS NULL THEN 0 ELSE 1 END';
EXEC dbo.m6_try NULL, 'E_drop_phone_column',            N'ALTER TABLE dbo.customer DROP COLUMN phone';
EXEC dbo.m6_try NULL, 'E_phone_values_in_old_instance', N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_CT WHERE phone IS NOT NULL';
EXEC dbo.m6_try NULL, 'E_new_instance',                 N'EXEC sys.sp_cdc_enable_table @source_schema = N''dbo'', @source_name = N''customer'', @role_name = NULL, @supports_net_changes = 1, @capture_instance = N''dbo_customer_v3''';
EXEC dbo.m6_try NULL, 'E_new_instance_captures_phone',  N'SELECT @n = COUNT(*) FROM cdc.captured_columns cc JOIN cdc.change_tables ct ON ct.object_id = cc.object_id WHERE ct.capture_instance = ''dbo_customer_v3'' AND cc.column_name = ''phone''';
EXEC dbo.m6_try NULL, 'E_old_instance_rows_before_disable', N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_CT';
EXEC dbo.m6_try NULL, 'E_disable_old_instance',         N'EXEC sys.sp_cdc_disable_table @source_schema = N''dbo'', @source_name = N''customer'', @capture_instance = N''dbo_customer''';
EXEC dbo.m6_try NULL, 'E_old_instance_table_exists',    N'SELECT @n = CASE WHEN OBJECT_ID(''cdc.dbo_customer_CT'') IS NULL THEN 0 ELSE 1 END';
EXEC dbo.m6_try NULL, 'E_new_instance_rows',            N'SELECT @n = COUNT(*) FROM cdc.dbo_customer_v3_CT';
GO
SELECT CONCAT('RESULT,', $(TRIAL), ',', k, ',', v) FROM dbo.m6_result ORDER BY seq;
GO
