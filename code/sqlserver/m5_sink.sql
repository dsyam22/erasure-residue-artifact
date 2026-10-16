-- m5_sink.sql  (measured run for F7: downstream copy)
-- sqlcmd variables: DB (database name), CONSUMER (CLAMP or STRICT), TRIAL
--   CLAMP  consumer moves its read window forward when older changes are no longer available
--   STRICT consumer does not; it asks for the window it expects
-- Fresh database per trial.
--   Part A: consumer keeps up. Subjects 31-40 are deleted, consumer runs.
--   Part B: consumer lags. Subjects 41-50 are deleted. Cleanup (1-minute retention) is started
--           every 30 s, with one unrelated change every 30 s, until no change rows remain for
--           subjects 41-50 (gives up after 40 minutes). Then the consumer runs.
-- Prints one line starting with RESULT,
SET NOCOUNT ON;
GO
-- Setup (create database, enable CDC) is serialized across parallel streams, because
-- concurrent CREATE DATABASE / CDC enabling on one instance can fail. Session-owned lock.
EXEC master.sys.sp_getapplock @Resource = 'm_setup', @LockMode = 'Exclusive',
     @LockOwner = 'Session', @LockTimeout = 900000;
GO
USE master;
GO
IF DB_ID('$(DB)') IS NOT NULL
BEGIN
    IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = '$(DB)') = 1
        EXEC [$(DB)].sys.sp_cdc_disable_db;
    ALTER DATABASE [$(DB)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$(DB)];
END
GO
CREATE DATABASE [$(DB)];
GO
USE [$(DB)];
GO
CREATE TABLE dbo.subscriber      (subscriber_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL);
CREATE TABLE dbo.subscriber_sink (subscriber_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL);
CREATE TABLE dbo.sink_state (id INT PRIMARY KEY, last_lsn BINARY(10) NULL);
INSERT dbo.sink_state VALUES (1, NULL);
CREATE TABLE dbo.consumer_log (run_no INT IDENTITY PRIMARY KEY, clamped BIT, deletes INT, upserts INT, err_number INT NULL);
CREATE TABLE dbo.metrics (k VARCHAR(40) PRIMARY KEY, v DECIMAL(12,2));
GO
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'subscriber',
     @role_name = NULL, @supports_net_changes = 1;
GO
EXEC master.sys.sp_releaseapplock @Resource = 'm_setup', @LockOwner = 'Session';
GO
CREATE PROCEDURE dbo.run_sink_consumer @strict BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @from BINARY(10), @to BINARY(10), @min BINARY(10), @clamped BIT = 0;
    DECLARE @deletes INT = 0, @upserts INT = 0, @err INT = NULL;

    SELECT @from = last_lsn FROM dbo.sink_state WHERE id = 1;
    SET @min = sys.fn_cdc_get_min_lsn('dbo_subscriber');
    SET @to  = sys.fn_cdc_get_max_lsn();
    IF @from IS NULL SET @from = @min; ELSE SET @from = sys.fn_cdc_increment_lsn(@from);

    IF @strict = 0 AND @from < @min
    BEGIN
        SET @from = @min;
        SET @clamped = 1;
    END

    IF @from <= @to
    BEGIN
        BEGIN TRY
            SELECT __$operation AS op, subscriber_id, full_name, email
            INTO #net
            FROM cdc.fn_cdc_get_net_changes_dbo_subscriber(@from, @to, 'all');

            DELETE s FROM dbo.subscriber_sink s JOIN #net n ON n.subscriber_id = s.subscriber_id WHERE n.op = 1;
            SET @deletes = @@ROWCOUNT;

            MERGE dbo.subscriber_sink AS s
            USING (SELECT subscriber_id, full_name, email FROM #net WHERE op IN (2, 4)) AS n
                ON s.subscriber_id = n.subscriber_id
            WHEN MATCHED THEN UPDATE SET full_name = n.full_name, email = n.email
            WHEN NOT MATCHED THEN INSERT (subscriber_id, full_name, email) VALUES (n.subscriber_id, n.full_name, n.email);
            SET @upserts = @@ROWCOUNT;

            UPDATE dbo.sink_state SET last_lsn = @to WHERE id = 1;
        END TRY
        BEGIN CATCH
            SET @err = ERROR_NUMBER();
        END CATCH
    END
    INSERT dbo.consumer_log (clamped, deletes, upserts, err_number) VALUES (@clamped, @deletes, @upserts, @err);
END
GO
;WITH n AS (SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
INSERT dbo.subscriber
SELECT i, CONCAT('Subject_', RIGHT(CONCAT('0000000', i), 7)), CONCAT('subject', i, '@example.invalid') FROM n;
GO
DECLARE @i INT = 0;
WHILE @i < 150 AND (SELECT COUNT(*) FROM cdc.dbo_subscriber_CT) < 100
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
GO
DECLARE @strict BIT = CASE '$(CONSUMER)' WHEN 'STRICT' THEN 1 ELSE 0 END;
DECLARE @i INT, @k INT, @t0 DATETIME;

EXEC dbo.run_sink_consumer @strict;                      -- run 1: initial load
INSERT dbo.metrics VALUES ('sink_rows_initial', (SELECT COUNT(*) FROM dbo.subscriber_sink));

-- Part A: consumer keeps up
DELETE FROM dbo.subscriber WHERE subscriber_id BETWEEN 31 AND 40;
SET @i = 0;
WHILE @i < 150 AND (SELECT COUNT(*) FROM cdc.dbo_subscriber_CT WHERE __$operation = 1 AND subscriber_id BETWEEN 31 AND 40) < 10
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
EXEC dbo.run_sink_consumer @strict;                      -- run 2
INSERT dbo.metrics VALUES ('partA_erased_left_in_sink',
    (SELECT COUNT(*) FROM dbo.subscriber_sink WHERE subscriber_id BETWEEN 31 AND 40));

-- Part B: consumer lags
DELETE FROM dbo.subscriber WHERE subscriber_id BETWEEN 41 AND 50;
SET @t0 = GETDATE();
SET @i = 0;
WHILE @i < 150 AND (SELECT COUNT(*) FROM cdc.dbo_subscriber_CT WHERE __$operation = 1 AND subscriber_id BETWEEN 41 AND 50) < 10
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END

EXEC sys.sp_cdc_change_job @job_type = N'cleanup', @retention = 1;
SET @k = 0;
DECLARE @present BIT = 1, @left INT = -1;
WHILE @k < 80 AND @present = 1
BEGIN
    UPDATE dbo.subscriber SET email = CONCAT('tick', @k, '@example.invalid') WHERE subscriber_id = 1;
    -- Ask for a cleanup run only when the job is not already running (see m4_cleanup.sql)
    IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobactivity a
                       JOIN msdb.dbo.sysjobs j ON j.job_id = a.job_id
                       WHERE j.name = CONCAT('cdc.', DB_NAME(), '_cleanup')
                         AND a.session_id = (SELECT MAX(session_id) FROM msdb.dbo.syssessions)
                         AND a.start_execution_date IS NOT NULL
                         AND a.stop_execution_date IS NULL)
    BEGIN
        BEGIN TRY EXEC sys.sp_cdc_start_job @job_type = N'cleanup'; END TRY BEGIN CATCH END CATCH
    END
    WAITFOR DELAY '00:00:30';
    -- The check can be chosen as a deadlock victim while cleanup is deleting; if so, look again
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM cdc.dbo_subscriber_CT WHERE subscriber_id BETWEEN 41 AND 50)
            SET @present = 0;
    END TRY
    BEGIN CATCH
    END CATCH
    SET @k += 1;
END
INSERT dbo.metrics VALUES ('minutes_until_stream_cleared', DATEDIFF(SECOND, @t0, GETDATE()) / 60.0);
SET @i = 0;
WHILE @i < 5 AND @left < 0
BEGIN
    BEGIN TRY
        SELECT @left = COUNT(*) FROM cdc.dbo_subscriber_CT WHERE subscriber_id BETWEEN 41 AND 50;
    END TRY
    BEGIN CATCH
        WAITFOR DELAY '00:00:05';
    END CATCH
    SET @i += 1;
END
INSERT dbo.metrics VALUES ('change_rows_left_for_erased', @left);

EXEC dbo.run_sink_consumer @strict;                      -- run 3: the lagging consumer
INSERT dbo.metrics VALUES ('partB_erased_left_in_sink',
    (SELECT COUNT(*) FROM dbo.subscriber_sink WHERE subscriber_id BETWEEN 41 AND 50));
INSERT dbo.metrics VALUES ('partB_erased_left_in_source',
    (SELECT COUNT(*) FROM dbo.subscriber WHERE subscriber_id BETWEEN 41 AND 50));
GO
SELECT CONCAT('RESULT,$(CONSUMER),', $(TRIAL), ',',
    CAST((SELECT v FROM dbo.metrics WHERE k = 'sink_rows_initial') AS INT), ',',
    CAST((SELECT v FROM dbo.metrics WHERE k = 'partA_erased_left_in_sink') AS INT), ',',
    (SELECT v FROM dbo.metrics WHERE k = 'minutes_until_stream_cleared'), ',',
    CAST((SELECT v FROM dbo.metrics WHERE k = 'change_rows_left_for_erased') AS INT), ',',
    CAST((SELECT v FROM dbo.metrics WHERE k = 'partB_erased_left_in_source') AS INT), ',',
    CAST((SELECT v FROM dbo.metrics WHERE k = 'partB_erased_left_in_sink') AS INT), ',',
    (SELECT CAST(clamped AS INT) FROM dbo.consumer_log WHERE run_no = 3), ',',
    ISNULL((SELECT err_number FROM dbo.consumer_log WHERE run_no = 3), 0), ',',
    (SELECT deletes FROM dbo.consumer_log WHERE run_no = 3));
GO
