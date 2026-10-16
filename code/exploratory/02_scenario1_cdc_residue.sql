-- 02_scenario1_cdc_residue.sql
-- Scenario 1 smoke test: does a deleted subject's data remain in the CDC change table?
-- Subject under test: customer_id = 42
SET NOCOUNT ON;
GO
USE erasure_lab;
GO

PRINT '--- Run timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS run_started_utc;

-- Give the capture job time to read the inserts from the log
WAITFOR DELAY '00:00:20';

PRINT '--- BEFORE delete ---';
SELECT COUNT(*) AS source_rows_for_subject
FROM dbo.customer WHERE customer_id = 42;

SELECT COUNT(*) AS change_table_rows_for_subject
FROM cdc.dbo_customer_CT WHERE customer_id = 42;

PRINT '--- Erasure: DELETE subject 42 ---';
DELETE FROM dbo.customer WHERE customer_id = 42;

-- Give the capture job time to read the delete from the log
WAITFOR DELAY '00:00:20';

PRINT '--- AFTER delete ---';
SELECT COUNT(*) AS source_rows_for_subject
FROM dbo.customer WHERE customer_id = 42;

PRINT '--- Change table contents for subject 42 ---';
PRINT '    operation: 1 = delete, 2 = insert, 3 = update (before), 4 = update (after)';
SELECT __$operation                              AS operation,
       sys.fn_cdc_map_lsn_to_time(__$start_lsn)  AS change_time,
       customer_id, full_name, email, phone
FROM cdc.dbo_customer_CT
WHERE customer_id = 42
ORDER BY __$start_lsn, __$seqval;
GO
