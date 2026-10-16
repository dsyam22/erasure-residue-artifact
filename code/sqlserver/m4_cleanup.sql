-- m4_cleanup.sql  (measured run for F6: CDC cleanup timing)
-- sqlcmd variables: DB (database name), RET (cleanup retention in minutes),
--                   ACTIVITY (0 = idle database, 1 = one unrelated change every 30 s), TRIAL
-- Fresh database per trial. Loads 100 subjects, deletes subject 42, then starts the cleanup
-- job every 30 seconds and records when subject 42's insert image and delete record disappear
-- from the change table. Gives up RET + 40 minutes after the erasure.
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
CREATE TABLE dbo.customer (
    customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL);
GO
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customer',
     @role_name = NULL, @supports_net_changes = 1;
GO
EXEC sys.sp_cdc_change_job @job_type = N'cleanup', @retention = $(RET);
GO
EXEC master.sys.sp_releaseapplock @Resource = 'm_setup', @LockOwner = 'Session';
GO
;WITH n AS (SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
INSERT dbo.customer (customer_id, full_name, email, phone)
SELECT i, CONCAT('Subject_', RIGHT(CONCAT('0000000', i), 7)),
       CONCAT('subject', i, '@example.invalid'), CONCAT('+1-555-', RIGHT(CONCAT('0000000', i), 7))
FROM n;
GO
DECLARE @i INT = 0;
WHILE @i < 150 AND (SELECT COUNT(*) FROM cdc.dbo_customer_CT) < 100
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
GO
DECLARE @t0 DATETIME, @ins_gone DATETIME, @del_gone DATETIME;
DECLARE @k INT = 0, @cap INT = ($(RET) + 40) * 2;
DECLARE @runs INT = 0, @runs_after_eligible_no_removal INT = 0, @i INT = 0;
DECLARE @read_errors INT = 0, @last_error INT = 0, @left INT = -1;

DELETE FROM dbo.customer WHERE customer_id = 42;
SET @t0 = GETDATE();

WHILE @i < 150 AND NOT EXISTS (SELECT 1 FROM cdc.dbo_customer_CT WHERE customer_id = 42 AND __$operation = 1)
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END

WHILE @k < @cap AND @del_gone IS NULL
BEGIN
    IF $(ACTIVITY) = 1
        UPDATE dbo.customer SET phone = CONCAT('tick-', @k) WHERE customer_id = 1;
    -- Ask for a cleanup run only when the job is not already running: a start request made
    -- while it is running raises an Agent error that ends the whole batch.
    IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobactivity a
                       JOIN msdb.dbo.sysjobs j ON j.job_id = a.job_id
                       WHERE j.name = CONCAT('cdc.', DB_NAME(), '_cleanup')
                         AND a.session_id = (SELECT MAX(session_id) FROM msdb.dbo.syssessions)
                         AND a.start_execution_date IS NOT NULL
                         AND a.stop_execution_date IS NULL)
    BEGIN
        BEGIN TRY
            EXEC sys.sp_cdc_start_job @job_type = N'cleanup';
            SET @runs += 1;
            IF @ins_gone IS NULL AND GETDATE() >= DATEADD(MINUTE, $(RET), @t0)
                SET @runs_after_eligible_no_removal += 1;
        END TRY
        BEGIN CATCH
        END CATCH
    END
    WAITFOR DELAY '00:00:30';
    -- The checks can be chosen as a deadlock victim while cleanup is deleting; if so, skip
    -- this poll and look again on the next one.
    BEGIN TRY
        IF @ins_gone IS NULL
           AND NOT EXISTS (SELECT 1 FROM cdc.dbo_customer_CT WHERE customer_id = 42 AND __$operation = 2)
        BEGIN
            SET @ins_gone = GETDATE();
            -- the run that did remove it was counted above; take it back out
            IF @runs_after_eligible_no_removal > 0 SET @runs_after_eligible_no_removal -= 1;
        END
        IF NOT EXISTS (SELECT 1 FROM cdc.dbo_customer_CT WHERE customer_id = 42 AND __$operation = 1)
            SET @del_gone = GETDATE();
    END TRY
    BEGIN CATCH
        SET @read_errors += 1;
        SET @last_error = ERROR_NUMBER();
    END CATCH
    SET @k += 1;
END

BEGIN TRY
    SELECT @left = COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id = 42;
END TRY
BEGIN CATCH
    SET @read_errors += 1;
    SET @last_error = ERROR_NUMBER();
END CATCH

SELECT CONCAT('RESULT,', $(RET), ',', $(ACTIVITY), ',', $(TRIAL), ',',
    CONVERT(VARCHAR(19), @t0, 120), ',',
    ISNULL(CAST(CAST(DATEDIFF(SECOND, @t0, @ins_gone) / 60.0 AS DECIMAL(8,2)) AS VARCHAR(20)), ''), ',',
    ISNULL(CAST(CAST(DATEDIFF(SECOND, @t0, @del_gone) / 60.0 AS DECIMAL(8,2)) AS VARCHAR(20)), ''), ',',
    @runs_after_eligible_no_removal, ',', @runs, ',',
    @left, ',',
    CASE WHEN @del_gone IS NULL THEN 1 ELSE 0 END, ',', @read_errors, ',', @last_error);
GO
