-- 06_config_drift_fix.sql
-- Configuration test for scenario 4: does a second capture instance fix schema drift?
--   Part A: create capture instance dbo_account_v2 - is national_id captured now?
--   Part B: are the old phone values still readable in the ORIGINAL change table?
--   Part C: disable the original capture instance - is its change table removed?
-- Requires: 05_scenario4_schema_drift.sql has been run, and 08 has NOT been run since.
SET NOCOUNT ON;
GO
USE erasure_lab;
GO

PRINT '--- Run timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS run_started_utc;

PRINT '=== PART A: add a second capture instance ===';
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE capture_instance = 'dbo_account_v2')
    EXEC sys.sp_cdc_enable_table
        @source_schema        = N'dbo',
        @source_name          = N'account',
        @role_name            = NULL,
        @capture_instance     = N'dbo_account_v2',
        @supports_net_changes = 1;
GO

UPDATE dbo.account SET national_id = 'SYN-000042-B' WHERE account_id = 42;
GO
WAITFOR DELAY '00:00:20';

PRINT '--- Capture instances and their columns ---';
SELECT ct.capture_instance, cc.column_name
FROM cdc.captured_columns cc
JOIN cdc.change_tables ct ON cc.object_id = ct.object_id
WHERE ct.source_object_id = OBJECT_ID('dbo.account')
ORDER BY ct.capture_instance, cc.column_ordinal;

PRINT '--- New change table (v2) rows for account 42 ---';
PRINT '    operation: 1 = delete, 2 = insert, 3 = update (before), 4 = update (after)';
SELECT __$operation AS operation, account_id, full_name, national_id
FROM cdc.dbo_account_v2_CT
WHERE account_id = 42
ORDER BY __$start_lsn, __$seqval, __$operation;
GO

PRINT '=== PART B: original change table - old phone values still readable? ===';
SELECT __$operation AS operation, account_id, full_name, phone
FROM cdc.dbo_account_CT
WHERE account_id IN (42, 43)
ORDER BY __$start_lsn, __$seqval, __$operation;
GO

PRINT '=== PART C: disable the original capture instance ===';
IF EXISTS (SELECT 1 FROM cdc.change_tables WHERE capture_instance = 'dbo_account')
    EXEC sys.sp_cdc_disable_table
        @source_schema    = N'dbo',
        @source_name      = N'account',
        @capture_instance = N'dbo_account';
GO

PRINT '--- Does the original change table still exist? (NULL = removed) ---';
SELECT OBJECT_ID('cdc.dbo_account_CT') AS original_change_table_object_id;

PRINT '--- Remaining capture instances for dbo.account ---';
SELECT capture_instance FROM cdc.change_tables
WHERE source_object_id = OBJECT_ID('dbo.account');
GO
