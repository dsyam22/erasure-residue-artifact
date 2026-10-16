-- 05_scenario4_schema_drift.sql
-- Scenario 4: schema changes after CDC is enabled.
--   Part A: a personal-data column ADDED later - is it captured?
--   Part B: a personal-data column DROPPED later - do old values stay in the change table?
-- Rerunnable: drops and recreates dbo.account each time. Synthetic data only.
-- Requires: 01_setup.sql has been run (database exists, CDC enabled on the database).
SET NOCOUNT ON;
GO
USE erasure_lab;
GO

IF OBJECT_ID('dbo.account') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM cdc.change_tables
               WHERE source_object_id = OBJECT_ID('dbo.account'))
        EXEC sys.sp_cdc_disable_table
            @source_schema    = N'dbo',
            @source_name      = N'account',
            @capture_instance = N'all';
    DROP TABLE dbo.account;
END
GO

CREATE TABLE dbo.account (
    account_id INT           NOT NULL PRIMARY KEY,
    full_name  NVARCHAR(100) NOT NULL,
    phone      NVARCHAR(30)  NULL
);
GO

EXEC sys.sp_cdc_enable_table
    @source_schema        = N'dbo',
    @source_name          = N'account',
    @role_name            = NULL,
    @supports_net_changes = 1;
GO

;WITH n AS (
    SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects
)
INSERT dbo.account (account_id, full_name, phone)
SELECT i,
       CONCAT('Subject_', RIGHT(CONCAT('000000', i), 6)),
       CONCAT('+1-555-', RIGHT(CONCAT('0000', i), 4))
FROM n;
GO

PRINT '--- Run timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS run_started_utc;
WAITFOR DELAY '00:00:20';

PRINT '--- Captured columns at the start ---';
SELECT cc.column_name
FROM cdc.captured_columns cc
JOIN cdc.change_tables ct ON cc.object_id = ct.object_id
WHERE ct.capture_instance = 'dbo_account'
ORDER BY cc.column_ordinal;
GO

PRINT '=== PART A: add a personal-data column after CDC was enabled ===';
ALTER TABLE dbo.account ADD national_id NVARCHAR(20) NULL;
GO

UPDATE dbo.account SET national_id = 'SYN-000042' WHERE account_id = 42;
INSERT dbo.account (account_id, full_name, phone, national_id)
VALUES (500, 'Subject_000500', '+1-555-0500', 'SYN-000500');
GO
WAITFOR DELAY '00:00:20';

PRINT '--- Source table now holds the new column ---';
SELECT account_id, full_name, phone, national_id
FROM dbo.account WHERE account_id IN (42, 500);

PRINT '--- Captured columns after the ADD (is national_id listed?) ---';
SELECT cc.column_name
FROM cdc.captured_columns cc
JOIN cdc.change_tables ct ON cc.object_id = ct.object_id
WHERE ct.capture_instance = 'dbo_account'
ORDER BY cc.column_ordinal;

PRINT '--- Change table rows for accounts 42 and 500 ---';
PRINT '    operation: 1 = delete, 2 = insert, 3 = update (before), 4 = update (after)';
SELECT __$operation AS operation, account_id, full_name, phone
FROM cdc.dbo_account_CT
WHERE account_id IN (42, 500)
ORDER BY __$start_lsn, __$seqval, __$operation;
GO

PRINT '=== PART B: drop a personal-data column from the source ===';
ALTER TABLE dbo.account DROP COLUMN phone;
GO

UPDATE dbo.account SET full_name = 'Subject_000043_renamed' WHERE account_id = 43;
GO
WAITFOR DELAY '00:00:20';

PRINT '--- Source table columns after the DROP ---';
SELECT name AS source_column FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.account') ORDER BY column_id;

PRINT '--- Captured columns after the DROP (is phone still listed?) ---';
SELECT cc.column_name
FROM cdc.captured_columns cc
JOIN cdc.change_tables ct ON cc.object_id = ct.object_id
WHERE ct.capture_instance = 'dbo_account'
ORDER BY cc.column_ordinal;

PRINT '--- Change table rows for accounts 42 and 43 (phone values still readable?) ---';
SELECT __$operation AS operation, account_id, full_name, phone
FROM cdc.dbo_account_CT
WHERE account_id IN (42, 43)
ORDER BY __$start_lsn, __$seqval, __$operation;

PRINT '--- DDL changes recorded by CDC ---';
SELECT ddl_time, ddl_command FROM cdc.ddl_history ORDER BY ddl_time;
GO
