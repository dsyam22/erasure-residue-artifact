-- 11_r2_followup.sql
-- Follow-up on the KEEP_CDC restore (database backup_lab_r2).
--   Part A: state after restore - CDC flag, jobs, change-table residue for subject 42
--   Part B: try to run cleanup with no cleanup job registered
--   Part C: change a row - is it captured when no capture job exists?
--   Part D: add the capture job - does the missed change appear afterwards?
--   Part E: add a cleanup job (1-minute retention) and run it - is the residue removed?
-- Requires: 10_backup_restore.sql has been run. To repeat this script, rerun 10 first.
-- An error message in Part B is an expected, informative outcome.
SET NOCOUNT ON;
GO
USE backup_lab_r2;
GO

PRINT '--- Run timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS run_started_utc;

PRINT '=== PART A: state after the KEEP_CDC restore ===';
SELECT name, is_cdc_enabled FROM sys.databases WHERE name = 'backup_lab_r2';

PRINT '--- CDC jobs registered for this database (no rows = none) ---';
SELECT job_type, retention FROM msdb.dbo.cdc_jobs WHERE database_id = DB_ID();

PRINT '--- Change table: total rows and rows for subject 42 ---';
SELECT COUNT(*) AS total_change_rows,
       SUM(CASE WHEN customer_id = 42 THEN 1 ELSE 0 END) AS rows_for_subject_42
FROM cdc.dbo_customer_CT;
GO

PRINT '=== PART B: try to start the cleanup job ===';
EXEC sys.sp_cdc_start_job @job_type = N'cleanup';
GO

PRINT '=== PART C: change subject 43 with no capture job present ===';
UPDATE dbo.customer SET full_name = 'Subject_000043_changed' WHERE customer_id = 43;
GO
WAITFOR DELAY '00:00:20';
GO
PRINT '--- Change table rows for subject 43 (only the original insert = change not captured) ---';
SELECT __$operation AS operation, customer_id, full_name
FROM cdc.dbo_customer_CT WHERE customer_id = 43
ORDER BY __$start_lsn, __$seqval, __$operation;
GO

PRINT '=== PART D: add the capture job ===';
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.cdc_jobs WHERE database_id = DB_ID() AND job_type = 'capture')
    EXEC sys.sp_cdc_add_job @job_type = N'capture';
GO
WAITFOR DELAY '00:00:30';
GO
PRINT '--- Change table rows for subject 43 after the capture job was added ---';
PRINT '    operation: 2 = insert, 3 = update (before), 4 = update (after)';
SELECT __$operation AS operation, customer_id, full_name
FROM cdc.dbo_customer_CT WHERE customer_id = 43
ORDER BY __$start_lsn, __$seqval, __$operation;
GO

PRINT '=== PART E: add a cleanup job with 1-minute retention and run it ===';
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.cdc_jobs WHERE database_id = DB_ID() AND job_type = 'cleanup')
    EXEC sys.sp_cdc_add_job @job_type = N'cleanup', @retention = 1;
GO
EXEC sys.sp_cdc_start_job @job_type = N'cleanup';
GO
WAITFOR DELAY '00:00:30';
GO
PRINT '--- CDC jobs registered now ---';
SELECT job_type, retention FROM msdb.dbo.cdc_jobs WHERE database_id = DB_ID();

PRINT '--- Change table after cleanup: total rows and rows for subject 42 ---';
SELECT COUNT(*) AS total_change_rows,
       SUM(CASE WHEN customer_id = 42 THEN 1 ELSE 0 END) AS rows_for_subject_42
FROM cdc.dbo_customer_CT;
GO
