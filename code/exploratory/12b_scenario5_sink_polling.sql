-- 12b_scenario5_sink_polling.sql
-- Scenario 5: a downstream copy fed by CDC.
-- dbo.subscriber is the source; dbo.subscriber_sink stands in for a downstream store.
-- dbo.run_sink_consumer is a small consumer that applies net changes, INCLUDING hard deletes.
-- If its read window starts below the oldest LSN still available, it clamps the window to
-- that LSN (a common pattern for avoiding the CDC "insufficient number of arguments" error).
--
--   Part A: consumer keeps up. Delete subject 42, run consumer. Does the sink lose subject 42?
--   Part B: consumer lags. Delete subject 43, then shorten CDC retention to 1 minute and run
--           cleanup (the fix for change-table residue), THEN run the consumer.
--           Does the delete still reach the sink?
--
-- Version b: Part B repeats cleanup once a minute (up to 25 times) until subject 43's change
-- rows are gone, and only then runs the consumer.
-- Runs in erasure_lab. Rerunnable. Synthetic data only. Takes up to about 27 minutes.
-- NOTE: cleanup applies to every capture instance in erasure_lab.
SET NOCOUNT ON;
GO
USE erasure_lab;
GO

IF OBJECT_ID('dbo.run_sink_consumer') IS NOT NULL DROP PROCEDURE dbo.run_sink_consumer;
GO
IF OBJECT_ID('dbo.subscriber') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.subscriber'))
        EXEC sys.sp_cdc_disable_table
            @source_schema = N'dbo', @source_name = N'subscriber', @capture_instance = N'all';
    DROP TABLE dbo.subscriber;
END
GO
IF OBJECT_ID('dbo.subscriber_sink') IS NOT NULL DROP TABLE dbo.subscriber_sink;
IF OBJECT_ID('dbo.sink_state')      IS NOT NULL DROP TABLE dbo.sink_state;
GO

CREATE TABLE dbo.subscriber (
    subscriber_id INT           NOT NULL PRIMARY KEY,
    full_name     NVARCHAR(100) NOT NULL,
    email         NVARCHAR(200) NOT NULL
);
CREATE TABLE dbo.subscriber_sink (
    subscriber_id INT           NOT NULL PRIMARY KEY,
    full_name     NVARCHAR(100) NOT NULL,
    email         NVARCHAR(200) NOT NULL
);
CREATE TABLE dbo.sink_state (id INT PRIMARY KEY, last_lsn BINARY(10) NULL);
INSERT dbo.sink_state VALUES (1, NULL);
GO

EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo', @source_name = N'subscriber',
    @role_name = NULL, @supports_net_changes = 1;
GO

CREATE PROCEDURE dbo.run_sink_consumer
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @from BINARY(10), @to BINARY(10), @min BINARY(10), @clamped BIT = 0;
    DECLARE @deletes INT = 0, @upserts INT = 0;

    SELECT @from = last_lsn FROM dbo.sink_state WHERE id = 1;
    SET @min = sys.fn_cdc_get_min_lsn('dbo_subscriber');
    SET @to  = sys.fn_cdc_get_max_lsn();

    IF @from IS NULL SET @from = @min;
    ELSE SET @from = sys.fn_cdc_increment_lsn(@from);

    IF @from < @min
    BEGIN
        SET @from = @min;
        SET @clamped = 1;
    END

    IF @from <= @to
    BEGIN
        SELECT __$operation AS op, subscriber_id, full_name, email
        INTO #net
        FROM cdc.fn_cdc_get_net_changes_dbo_subscriber(@from, @to, 'all');

        DELETE s FROM dbo.subscriber_sink s
        JOIN #net n ON n.subscriber_id = s.subscriber_id
        WHERE n.op = 1;
        SET @deletes = @@ROWCOUNT;

        MERGE dbo.subscriber_sink AS s
        USING (SELECT subscriber_id, full_name, email FROM #net WHERE op IN (2, 4)) AS n
            ON s.subscriber_id = n.subscriber_id
        WHEN MATCHED THEN UPDATE SET full_name = n.full_name, email = n.email
        WHEN NOT MATCHED THEN INSERT (subscriber_id, full_name, email)
                              VALUES (n.subscriber_id, n.full_name, n.email);
        SET @upserts = @@ROWCOUNT;

        UPDATE dbo.sink_state SET last_lsn = @to WHERE id = 1;
    END

    SELECT @clamped AS window_was_clamped, @deletes AS deletes_applied, @upserts AS upserts_applied;
END
GO

;WITH n AS (
    SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects
)
INSERT dbo.subscriber (subscriber_id, full_name, email)
SELECT i, CONCAT('Subject_', RIGHT(CONCAT('000000', i), 6)), CONCAT('subject', i, '@example.invalid')
FROM n;
GO
WAITFOR DELAY '00:00:20';
GO

PRINT '--- Run timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS run_started_utc;

PRINT '--- Initial load: consumer run 1 ---';
EXEC dbo.run_sink_consumer;
SELECT COUNT(*) AS sink_rows FROM dbo.subscriber_sink;
GO

PRINT '=== PART A: consumer keeps up ===';
DELETE FROM dbo.subscriber WHERE subscriber_id = 42;
GO
WAITFOR DELAY '00:00:20';
GO
PRINT '--- Consumer run 2 ---';
EXEC dbo.run_sink_consumer;
PRINT '--- Subject 42 in the sink (no rows = delete propagated) ---';
SELECT subscriber_id, full_name, email FROM dbo.subscriber_sink WHERE subscriber_id = 42;
GO

PRINT '=== PART B: consumer lags, cleanup runs first ===';
DELETE FROM dbo.subscriber WHERE subscriber_id = 43;
GO
WAITFOR DELAY '00:00:20';
GO
PRINT '--- Delete of subject 43 is in the change table (operation 1 = delete) ---';
SELECT __$operation AS operation, subscriber_id, full_name, email
FROM cdc.dbo_subscriber_CT WHERE subscriber_id = 43
ORDER BY __$start_lsn, __$seqval, __$operation;
GO

PRINT '--- Cleanup at 1-minute retention, repeated once a minute until subject 43 is gone ---';
EXEC sys.sp_cdc_change_job @job_type = N'cleanup', @retention = 1;
GO
DECLARE @tries INT = 0, @started DATETIME = GETDATE();
WHILE @tries < 25
      AND EXISTS (SELECT 1 FROM cdc.dbo_subscriber_CT WHERE subscriber_id = 43)
BEGIN
    BEGIN TRY
        EXEC sys.sp_cdc_start_job @job_type = N'cleanup';
    END TRY
    BEGIN CATCH
        PRINT CONCAT('cleanup start skipped: ', ERROR_MESSAGE());
    END CATCH
    WAITFOR DELAY '00:01:00';
    SET @tries += 1;
END
SELECT @tries AS cleanup_runs,
       DATEDIFF(SECOND, @started, GETDATE()) / 60.0 AS minutes_waited,
       (SELECT COUNT(*) FROM cdc.dbo_subscriber_CT WHERE subscriber_id = 43) AS change_rows_for_subject_43_left;
GO
PRINT '--- Change table rows for subject 43 after cleanup ---';
SELECT COUNT(*) AS change_rows_for_subject_43
FROM cdc.dbo_subscriber_CT WHERE subscriber_id = 43;
GO

PRINT '--- Consumer run 3 (after cleanup) ---';
EXEC dbo.run_sink_consumer;
GO
PRINT '--- Subject 43: source table ---';
SELECT COUNT(*) AS source_rows_for_subject_43 FROM dbo.subscriber WHERE subscriber_id = 43;
PRINT '--- Subject 43: sink (a row here = erased at source, still present downstream) ---';
SELECT subscriber_id, full_name, email FROM dbo.subscriber_sink WHERE subscriber_id = 43;
PRINT '--- Row counts ---';
SELECT (SELECT COUNT(*) FROM dbo.subscriber)      AS source_rows,
       (SELECT COUNT(*) FROM dbo.subscriber_sink) AS sink_rows;
GO

PRINT '=== Restore default retention ===';
EXEC sys.sp_cdc_change_job @job_type = N'cleanup', @retention = 4320;
GO
