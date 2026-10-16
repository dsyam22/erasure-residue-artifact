-- 08_config_cdc_cleanup.sql
-- Configuration test for scenarios 1 and 3 (CDC change table).
--   Part A: run the cleanup job at the DEFAULT retention (4320 min) - is residue removed?
--   Part B: lower retention to 1 minute, run cleanup again - is residue removed?
--   Part C: restore the default retention.
-- NOTE: cleanup applies to every capture instance in the database. Run this LAST,
--       after 06 and 07, because it removes the residue the other scripts look at.
SET NOCOUNT ON;
GO
USE erasure_lab;
GO

PRINT '--- Run timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS run_started_utc;

PRINT '--- BEFORE: change table rows ---';
SELECT customer_id, COUNT(*) AS change_rows
FROM cdc.dbo_customer_CT WHERE customer_id IN (42, 77) GROUP BY customer_id;
SELECT COUNT(*) AS total_change_rows FROM cdc.dbo_customer_CT;
GO

PRINT '=== PART A: cleanup at default retention ===';
EXEC sys.sp_cdc_start_job @job_type = N'cleanup';
GO
WAITFOR DELAY '00:00:30';
SELECT customer_id, COUNT(*) AS change_rows
FROM cdc.dbo_customer_CT WHERE customer_id IN (42, 77) GROUP BY customer_id;
SELECT COUNT(*) AS total_change_rows FROM cdc.dbo_customer_CT;
GO

PRINT '=== PART B: retention lowered to 1 minute, cleanup again ===';
EXEC sys.sp_cdc_change_job @job_type = N'cleanup', @retention = 1;
GO
EXEC sys.sp_cdc_start_job @job_type = N'cleanup';
GO
WAITFOR DELAY '00:00:30';
SELECT SYSUTCDATETIME() AS checked_at_utc;
SELECT customer_id, COUNT(*) AS change_rows
FROM cdc.dbo_customer_CT WHERE customer_id IN (42, 77) GROUP BY customer_id;
SELECT COUNT(*) AS total_change_rows FROM cdc.dbo_customer_CT;

PRINT '--- Any rows left for subjects 42 and 77? ---';
SELECT __$operation AS operation,
       sys.fn_cdc_map_lsn_to_time(__$start_lsn) AS change_time,
       customer_id, full_name, email, phone
FROM cdc.dbo_customer_CT
WHERE customer_id IN (42, 77)
ORDER BY __$start_lsn, __$seqval, __$operation;
GO

PRINT '=== PART C: restore default retention ===';
EXEC sys.sp_cdc_change_job @job_type = N'cleanup', @retention = 4320;
GO
EXEC sys.sp_cdc_help_jobs;
GO
