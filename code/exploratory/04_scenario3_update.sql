-- 04_scenario3_update.sql
-- Scenario 3: "erase" by overwriting personal fields with an UPDATE.
-- Do the original values survive as before-images in CDC and temporal history?
-- Requires: 01_setup.sql and 03_scenario2_temporal.sql have been run.
-- Subject under test: id = 77 in dbo.customer (CDC) and dbo.member (temporal).
SET NOCOUNT ON;
GO
USE erasure_lab;
GO

PRINT '--- Run timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS run_started_utc;

PRINT '--- BEFORE update ---';
SELECT 'customer' AS tbl, customer_id AS id, full_name, email, phone FROM dbo.customer WHERE customer_id = 77;
SELECT 'member'   AS tbl, member_id   AS id, full_name, email, phone FROM dbo.member   WHERE member_id   = 77;

PRINT '--- Erasure by overwrite: UPDATE subject 77 in both tables ---';
UPDATE dbo.customer
SET full_name = 'REDACTED', email = 'redacted@example.invalid', phone = NULL
WHERE customer_id = 77;

UPDATE dbo.member
SET full_name = 'REDACTED', email = 'redacted@example.invalid', phone = NULL
WHERE member_id = 77;

-- Give the CDC capture job time to read the update from the log
WAITFOR DELAY '00:00:20';

PRINT '--- AFTER update: source tables ---';
SELECT 'customer' AS tbl, customer_id AS id, full_name, email, phone FROM dbo.customer WHERE customer_id = 77;
SELECT 'member'   AS tbl, member_id   AS id, full_name, email, phone FROM dbo.member   WHERE member_id   = 77;

PRINT '--- CDC change table for subject 77 ---';
PRINT '    operation: 1 = delete, 2 = insert, 3 = update (before), 4 = update (after)';
SELECT __$operation                             AS operation,
       sys.fn_cdc_map_lsn_to_time(__$start_lsn) AS change_time,
       customer_id, full_name, email, phone
FROM cdc.dbo_customer_CT
WHERE customer_id = 77
ORDER BY __$start_lsn, __$seqval, __$operation;

PRINT '--- Temporal history table for subject 77 ---';
SELECT member_id, full_name, email, phone, valid_from, valid_to
FROM dbo.member_history WHERE member_id = 77;
GO
