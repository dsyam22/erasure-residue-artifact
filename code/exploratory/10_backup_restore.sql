-- 10_backup_restore.sql
-- Backup and restore experiment, in its own databases (does not touch erasure_lab).
--
-- Timeline in database backup_lab:
--   1. Create a CDC table (customer) and a temporal table (member, 1 DAY retention).
--   2. FULL BACKUP                      <- taken BEFORE the erasure
--   3. Record a time mark
--   4. Erase subject 42 from both tables
--   5. LOG BACKUP                       <- covers the erasure
--
-- Three restores, each into a new database:
--   R1 backup_lab_r1 : full backup, default options
--   R2 backup_lab_r2 : full backup WITH KEEP_CDC
--   R3 backup_lab_r3 : full + log, point-in-time restore to the mark (before the erasure)
--
-- Questions:
--   Q1. Does the erased subject come back in the restored databases?
--   Q2. Do the CDC change tables (and their copies of the subject) come back?
--   Q3. Is CDC still enabled / are its jobs present after a restore?
--   Q4. Is temporal retention cleanup still enabled after a restore?
--
-- Rerunnable: drops and recreates all four databases. Synthetic data only.
SET NOCOUNT ON;
GO
USE master;
GO

DECLARE @db SYSNAME, @sql NVARCHAR(MAX);
DECLARE dbs CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM sys.databases
    WHERE name IN ('backup_lab', 'backup_lab_r1', 'backup_lab_r2', 'backup_lab_r3');
OPEN dbs;
FETCH NEXT FROM dbs INTO @db;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = @db) = 1
    BEGIN
        SET @sql = N'EXEC ' + QUOTENAME(@db) + N'.sys.sp_cdc_disable_db;';
        EXEC (@sql);
    END
    SET @sql = N'ALTER DATABASE ' + QUOTENAME(@db) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; '
             + N'DROP DATABASE ' + QUOTENAME(@db) + N';';
    EXEC (@sql);
    FETCH NEXT FROM dbs INTO @db;
END
CLOSE dbs;
DEALLOCATE dbs;
GO

CREATE DATABASE backup_lab;
GO
ALTER DATABASE backup_lab SET RECOVERY FULL;
GO
USE backup_lab;
GO

CREATE TABLE dbo.customer (
    customer_id INT           NOT NULL PRIMARY KEY,
    full_name   NVARCHAR(100) NOT NULL,
    email       NVARCHAR(200) NOT NULL
);
CREATE TABLE dbo.member (
    member_id  INT           NOT NULL PRIMARY KEY,
    full_name  NVARCHAR(100) NOT NULL,
    email      NVARCHAR(200) NOT NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    valid_to   DATETIME2 GENERATED ALWAYS AS ROW END   NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.member_history,
                              HISTORY_RETENTION_PERIOD = 1 DAY));
CREATE TABLE dbo.run_marks (mark_name VARCHAR(30) PRIMARY KEY, mark_time DATETIME NOT NULL);
GO

EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo', @source_name = N'customer',
    @role_name = NULL, @supports_net_changes = 1;
GO

;WITH n AS (
    SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects
)
INSERT dbo.customer (customer_id, full_name, email)
SELECT i, CONCAT('Subject_', RIGHT(CONCAT('000000', i), 6)), CONCAT('subject', i, '@example.invalid')
FROM n;

;WITH n AS (
    SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects
)
INSERT dbo.member (member_id, full_name, email)
SELECT i, CONCAT('Subject_', RIGHT(CONCAT('000000', i), 6)), CONCAT('subject', i, '@example.invalid')
FROM n;
GO

-- Let the capture job read the inserts before the backup
WAITFOR DELAY '00:00:20';
GO

PRINT '--- Run timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS run_started_utc;

PRINT '=== Step 2: FULL BACKUP (before erasure) ===';
BACKUP DATABASE backup_lab
    TO DISK = N'/var/opt/mssql/data/backup_lab_full.bak'
    WITH INIT, FORMAT;
GO

PRINT '=== Step 3: time mark ===';
WAITFOR DELAY '00:00:03';
INSERT dbo.run_marks VALUES ('before_erasure', GETDATE());
WAITFOR DELAY '00:00:03';
SELECT mark_name, mark_time FROM dbo.run_marks;
GO

PRINT '=== Step 4: erase subject 42 from both tables ===';
DELETE FROM dbo.customer WHERE customer_id = 42;
DELETE FROM dbo.member   WHERE member_id   = 42;
GO
WAITFOR DELAY '00:00:20';
GO

PRINT '--- Source database after erasure ---';
SELECT (SELECT COUNT(*) FROM dbo.customer WHERE customer_id = 42) AS customer_rows_42,
       (SELECT COUNT(*) FROM dbo.member   WHERE member_id   = 42) AS member_rows_42;
GO

PRINT '=== Step 5: LOG BACKUP (covers the erasure) ===';
BACKUP LOG backup_lab
    TO DISK = N'/var/opt/mssql/data/backup_lab_log.trn'
    WITH INIT, FORMAT;
GO

USE master;
GO

PRINT '=== R1: restore full backup, default options ===';
RESTORE DATABASE backup_lab_r1
    FROM DISK = N'/var/opt/mssql/data/backup_lab_full.bak'
    WITH MOVE N'backup_lab'     TO N'/var/opt/mssql/data/backup_lab_r1.mdf',
         MOVE N'backup_lab_log' TO N'/var/opt/mssql/data/backup_lab_r1_log.ldf',
         RECOVERY;
GO

PRINT '=== R2: restore full backup WITH KEEP_CDC ===';
RESTORE DATABASE backup_lab_r2
    FROM DISK = N'/var/opt/mssql/data/backup_lab_full.bak'
    WITH MOVE N'backup_lab'     TO N'/var/opt/mssql/data/backup_lab_r2.mdf',
         MOVE N'backup_lab_log' TO N'/var/opt/mssql/data/backup_lab_r2_log.ldf',
         KEEP_CDC, RECOVERY;
GO

PRINT '=== R3: point-in-time restore to the mark (before erasure) ===';
RESTORE DATABASE backup_lab_r3
    FROM DISK = N'/var/opt/mssql/data/backup_lab_full.bak'
    WITH MOVE N'backup_lab'     TO N'/var/opt/mssql/data/backup_lab_r3.mdf',
         MOVE N'backup_lab_log' TO N'/var/opt/mssql/data/backup_lab_r3_log.ldf',
         NORECOVERY;
GO
DECLARE @t DATETIME;
SELECT @t = mark_time FROM backup_lab.dbo.run_marks WHERE mark_name = 'before_erasure';
RESTORE LOG backup_lab_r3
    FROM DISK = N'/var/opt/mssql/data/backup_lab_log.trn'
    WITH STOPAT = @t, RECOVERY;
GO

PRINT '=== RESULTS ===';
PRINT '--- Q3 and Q4: database-level flags ---';
SELECT name, is_cdc_enabled, is_temporal_history_retention_enabled, recovery_model_desc
FROM sys.databases
WHERE name LIKE 'backup_lab%'
ORDER BY name;

PRINT '--- Q3: CDC jobs registered per database ---';
SELECT name AS job_name FROM msdb.dbo.sysjobs WHERE name LIKE 'cdc.backup_lab%' ORDER BY name;
GO

PRINT '--- Q1: is subject 42 present? (source rows) ---';
SELECT 'backup_lab (source, erased)' AS db,
       (SELECT COUNT(*) FROM backup_lab.dbo.customer WHERE customer_id = 42) AS customer_rows_42,
       (SELECT COUNT(*) FROM backup_lab.dbo.member   WHERE member_id   = 42) AS member_rows_42
UNION ALL
SELECT 'backup_lab_r1',
       (SELECT COUNT(*) FROM backup_lab_r1.dbo.customer WHERE customer_id = 42),
       (SELECT COUNT(*) FROM backup_lab_r1.dbo.member   WHERE member_id   = 42)
UNION ALL
SELECT 'backup_lab_r2',
       (SELECT COUNT(*) FROM backup_lab_r2.dbo.customer WHERE customer_id = 42),
       (SELECT COUNT(*) FROM backup_lab_r2.dbo.member   WHERE member_id   = 42)
UNION ALL
SELECT 'backup_lab_r3',
       (SELECT COUNT(*) FROM backup_lab_r3.dbo.customer WHERE customer_id = 42),
       (SELECT COUNT(*) FROM backup_lab_r3.dbo.member   WHERE member_id   = 42);
GO

PRINT '--- Q2: does the CDC change table exist in each database? (NULL = no) ---';
SELECT 'backup_lab'    AS db, OBJECT_ID('backup_lab.cdc.dbo_customer_CT')    AS change_table_object_id
UNION ALL
SELECT 'backup_lab_r1', OBJECT_ID('backup_lab_r1.cdc.dbo_customer_CT')
UNION ALL
SELECT 'backup_lab_r2', OBJECT_ID('backup_lab_r2.cdc.dbo_customer_CT')
UNION ALL
SELECT 'backup_lab_r3', OBJECT_ID('backup_lab_r3.cdc.dbo_customer_CT');
GO

PRINT '--- Q2: change table rows for subject 42 in R2 (an error here means the table is absent) ---';
SELECT __$operation AS operation, customer_id, full_name, email
FROM backup_lab_r2.cdc.dbo_customer_CT
WHERE customer_id = 42
ORDER BY __$start_lsn, __$seqval, __$operation;
GO
