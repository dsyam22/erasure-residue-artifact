-- 14_cleanup_probe.sql
-- Diagnostic: why did CDC cleanup at 1-minute retention report success but remove nothing?
-- For two databases it records the clock, the retention setting, the age of the change rows,
-- the capture instance's low watermark and the LSN-time mapping, then runs cleanup at
-- 1-minute retention and records the same values again.
-- The change rows are now several minutes older than when scripts 11 and 12 ran.
SET NOCOUNT ON;
GO
PRINT '================ erasure_lab / dbo_subscriber ================';
USE erasure_lab;
GO

PRINT '--- BEFORE: clock, retention, change-table state ---';
SELECT GETDATE() AS server_time, DATEADD(MINUTE, -1, GETDATE()) AS one_minute_cutoff;
SELECT job_type, retention FROM msdb.dbo.cdc_jobs WHERE database_id = DB_ID();
SELECT COUNT(*) AS change_rows,
       sys.fn_cdc_map_lsn_to_time(MIN(__$start_lsn)) AS oldest_change_time,
       sys.fn_cdc_map_lsn_to_time(MAX(__$start_lsn)) AS newest_change_time
FROM cdc.dbo_subscriber_CT;
SELECT capture_instance, start_lsn AS low_watermark_lsn,
       sys.fn_cdc_map_lsn_to_time(start_lsn) AS low_watermark_time
FROM cdc.change_tables WHERE capture_instance = 'dbo_subscriber';
SELECT COUNT(*) AS mapping_rows, MIN(tran_end_time) AS oldest_mapping_time,
       MAX(tran_end_time) AS newest_mapping_time
FROM cdc.lsn_time_mapping;
SELECT sys.fn_cdc_map_time_to_lsn('largest less than or equal', DATEADD(MINUTE, -1, GETDATE())) AS lsn_at_cutoff,
       sys.fn_cdc_map_lsn_to_time(
           sys.fn_cdc_map_time_to_lsn('largest less than or equal', DATEADD(MINUTE, -1, GETDATE()))) AS time_at_cutoff;
GO
EXEC sys.sp_cdc_change_job @job_type = N'cleanup', @retention = 1;
GO
EXEC sys.sp_cdc_start_job @job_type = N'cleanup';
GO
WAITFOR DELAY '00:00:30';
GO
PRINT '--- AFTER cleanup at 1-minute retention ---';
SELECT GETDATE() AS server_time;
SELECT COUNT(*) AS change_rows,
       sys.fn_cdc_map_lsn_to_time(MIN(__$start_lsn)) AS oldest_change_time,
       sys.fn_cdc_map_lsn_to_time(MAX(__$start_lsn)) AS newest_change_time
FROM cdc.dbo_subscriber_CT;
SELECT capture_instance, start_lsn AS low_watermark_lsn,
       sys.fn_cdc_map_lsn_to_time(start_lsn) AS low_watermark_time
FROM cdc.change_tables WHERE capture_instance = 'dbo_subscriber';
SELECT COUNT(*) AS mapping_rows, MIN(tran_end_time) AS oldest_mapping_time,
       MAX(tran_end_time) AS newest_mapping_time
FROM cdc.lsn_time_mapping;
GO
EXEC sys.sp_cdc_change_job @job_type = N'cleanup', @retention = 4320;
GO
PRINT '================ backup_lab_r2 / dbo_customer ================';
USE backup_lab_r2;
GO

PRINT '--- BEFORE: clock, retention, change-table state ---';
SELECT GETDATE() AS server_time, DATEADD(MINUTE, -1, GETDATE()) AS one_minute_cutoff;
SELECT job_type, retention FROM msdb.dbo.cdc_jobs WHERE database_id = DB_ID();
SELECT COUNT(*) AS change_rows,
       sys.fn_cdc_map_lsn_to_time(MIN(__$start_lsn)) AS oldest_change_time,
       sys.fn_cdc_map_lsn_to_time(MAX(__$start_lsn)) AS newest_change_time
FROM cdc.dbo_customer_CT;
SELECT capture_instance, start_lsn AS low_watermark_lsn,
       sys.fn_cdc_map_lsn_to_time(start_lsn) AS low_watermark_time
FROM cdc.change_tables WHERE capture_instance = 'dbo_customer';
SELECT COUNT(*) AS mapping_rows, MIN(tran_end_time) AS oldest_mapping_time,
       MAX(tran_end_time) AS newest_mapping_time
FROM cdc.lsn_time_mapping;
SELECT sys.fn_cdc_map_time_to_lsn('largest less than or equal', DATEADD(MINUTE, -1, GETDATE())) AS lsn_at_cutoff,
       sys.fn_cdc_map_lsn_to_time(
           sys.fn_cdc_map_time_to_lsn('largest less than or equal', DATEADD(MINUTE, -1, GETDATE()))) AS time_at_cutoff;
GO
EXEC sys.sp_cdc_change_job @job_type = N'cleanup', @retention = 1;
GO
EXEC sys.sp_cdc_start_job @job_type = N'cleanup';
GO
WAITFOR DELAY '00:00:30';
GO
PRINT '--- AFTER cleanup at 1-minute retention ---';
SELECT GETDATE() AS server_time;
SELECT COUNT(*) AS change_rows,
       sys.fn_cdc_map_lsn_to_time(MIN(__$start_lsn)) AS oldest_change_time,
       sys.fn_cdc_map_lsn_to_time(MAX(__$start_lsn)) AS newest_change_time
FROM cdc.dbo_customer_CT;
SELECT capture_instance, start_lsn AS low_watermark_lsn,
       sys.fn_cdc_map_lsn_to_time(start_lsn) AS low_watermark_time
FROM cdc.change_tables WHERE capture_instance = 'dbo_customer';
SELECT COUNT(*) AS mapping_rows, MIN(tran_end_time) AS oldest_mapping_time,
       MAX(tran_end_time) AS newest_mapping_time
FROM cdc.lsn_time_mapping;
GO
PRINT '--- Rows left for subject 42 in the restored copy ---';
SELECT COUNT(*) AS rows_for_subject_42 FROM cdc.dbo_customer_CT WHERE customer_id = 42;
GO
