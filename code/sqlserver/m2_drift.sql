-- m2_drift.sql  (measured run for F4)
-- sqlcmd variable: TRIAL
-- Fresh database per trial. Adds a personal-data column after CDC is enabled and updates it
-- for all 100 rows; then drops a different personal-data column. Prints one RESULT line.
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
CREATE TABLE dbo.account (
    account_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, phone NVARCHAR(30) NULL);
GO
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'account',
     @role_name = NULL, @supports_net_changes = 1;
GO
;WITH n AS (SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
INSERT dbo.account (account_id, full_name, phone)
SELECT i, CONCAT('Subject_', RIGHT(CONCAT('0000000', i), 7)), CONCAT('+1-555-', RIGHT(CONCAT('0000000', i), 7))
FROM n;
GO
DECLARE @i INT = 0;
WHILE @i < 150 AND (SELECT COUNT(*) FROM cdc.dbo_account_CT) < 100
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
GO
-- Part A: add a personal-data column, set it for all 100 rows, then insert a marker row
ALTER TABLE dbo.account ADD national_id NVARCHAR(20) NULL;
GO
UPDATE dbo.account SET national_id = CONCAT('SYN-', account_id);
INSERT dbo.account (account_id, full_name, phone, national_id)
VALUES (500, 'Subject_0000500', '+1-555-0000500', 'SYN-500');
GO
-- The marker row's insert tells us capture has passed the 100 updates (max 5 minutes)
DECLARE @i INT = 0;
WHILE @i < 150 AND NOT EXISTS (SELECT 1 FROM cdc.dbo_account_CT WHERE account_id = 500)
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
INSERT dbo.metrics VALUES ('marker_captured',
    (SELECT COUNT(*) FROM cdc.dbo_account_CT WHERE account_id = 500));
INSERT dbo.metrics VALUES ('added_col_captured',
    (SELECT COUNT(*) FROM cdc.captured_columns cc JOIN cdc.change_tables ct ON cc.object_id = ct.object_id
      WHERE ct.capture_instance = 'dbo_account' AND cc.column_name = 'national_id'));
INSERT dbo.metrics VALUES ('updates_made', 100);
INSERT dbo.metrics VALUES ('updates_recorded',
    (SELECT COUNT(*) FROM cdc.dbo_account_CT WHERE __$operation = 4));
GO
-- Part B: drop a personal-data column, then make one more change as a marker
ALTER TABLE dbo.account DROP COLUMN phone;
GO
UPDATE dbo.account SET full_name = CONCAT(full_name, '_x') WHERE account_id = 43;
GO
DECLARE @i INT = 0;
WHILE @i < 150 AND NOT EXISTS (SELECT 1 FROM cdc.dbo_account_CT WHERE account_id = 43 AND __$operation = 4)
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
INSERT dbo.metrics VALUES ('dropped_col_in_source',
    (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('dbo.account') AND name = 'phone'));
INSERT dbo.metrics VALUES ('dropped_col_still_captured',
    (SELECT COUNT(*) FROM cdc.captured_columns cc JOIN cdc.change_tables ct ON cc.object_id = ct.object_id
      WHERE ct.capture_instance = 'dbo_account' AND cc.column_name = 'phone'));
GO
INSERT dbo.metrics VALUES ('dropped_values_readable',
    (SELECT COUNT(*) FROM cdc.dbo_account_CT WHERE phone IS NOT NULL));
GO
SELECT CONCAT('RESULT,', $(TRIAL), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'marker_captured'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'added_col_captured'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'updates_made'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'updates_recorded'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'dropped_col_in_source'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'dropped_col_still_captured'), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'dropped_values_readable'));
GO
