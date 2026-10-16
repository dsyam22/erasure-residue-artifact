-- m3_restore.sql  (measured run for F8)
-- sqlcmd variable: TRIAL
-- Source database m_bk: CDC table + temporal table (1 DAY retention). Full backup, erase
-- subject 42, log backup. Four restore sequences, each into a new database:
--   R1 full, default options          R2 full WITH KEEP_CDC
--   R3 full + log, STOPAT before the erasure     R4 full + log to the end
-- Prints four RESULT lines (one per sequence).
SET NOCOUNT ON;
GO
USE master;
GO
DECLARE @db SYSNAME, @sql NVARCHAR(MAX);
DECLARE dbs CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM sys.databases WHERE name IN ('m_bk', 'm_bk_r1', 'm_bk_r2', 'm_bk_r3', 'm_bk_r4');
OPEN dbs;
FETCH NEXT FROM dbs INTO @db;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = @db) = 1
    BEGIN
        SET @sql = N'EXEC ' + QUOTENAME(@db) + N'.sys.sp_cdc_disable_db;';
        EXEC (@sql);
    END
    SET @sql = N'ALTER DATABASE ' + QUOTENAME(@db) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE '
             + QUOTENAME(@db) + N';';
    EXEC (@sql);
    FETCH NEXT FROM dbs INTO @db;
END
CLOSE dbs; DEALLOCATE dbs;
GO
CREATE DATABASE m_bk;
GO
ALTER DATABASE m_bk SET RECOVERY FULL;
GO
USE m_bk;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL);
CREATE TABLE dbo.member (
    member_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    valid_to   DATETIME2 GENERATED ALWAYS AS ROW END   NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.member_history, HISTORY_RETENTION_PERIOD = 1 DAY));
CREATE TABLE dbo.run_marks (mark_name VARCHAR(30) PRIMARY KEY, mark_time DATETIME NOT NULL);
GO
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customer',
     @role_name = NULL, @supports_net_changes = 1;
GO
;WITH n AS (SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
INSERT dbo.customer SELECT i, CONCAT('Subject_', RIGHT(CONCAT('0000000', i), 7)), CONCAT('subject', i, '@example.invalid') FROM n;
INSERT dbo.member (member_id, full_name, email) SELECT customer_id, full_name, email FROM dbo.customer;
GO
DECLARE @i INT = 0;
WHILE @i < 150 AND (SELECT COUNT(*) FROM cdc.dbo_customer_CT) < 100
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
GO
BACKUP DATABASE m_bk TO DISK = N'/var/opt/mssql/data/m_bk_full.bak' WITH INIT, FORMAT;
GO
WAITFOR DELAY '00:00:03';
INSERT dbo.run_marks VALUES ('before_erasure', GETDATE());
WAITFOR DELAY '00:00:03';
GO
DELETE FROM dbo.customer WHERE customer_id = 42;
DELETE FROM dbo.member   WHERE member_id   = 42;
GO
DECLARE @i INT = 0;
WHILE @i < 150 AND NOT EXISTS (SELECT 1 FROM cdc.dbo_customer_CT WHERE customer_id = 42 AND __$operation = 1)
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
GO
BACKUP LOG m_bk TO DISK = N'/var/opt/mssql/data/m_bk_log.trn' WITH INIT, FORMAT;
GO
USE master;
GO
RESTORE DATABASE m_bk_r1 FROM DISK = N'/var/opt/mssql/data/m_bk_full.bak'
    WITH MOVE N'm_bk' TO N'/var/opt/mssql/data/m_bk_r1.mdf',
         MOVE N'm_bk_log' TO N'/var/opt/mssql/data/m_bk_r1_log.ldf', RECOVERY;
GO
RESTORE DATABASE m_bk_r2 FROM DISK = N'/var/opt/mssql/data/m_bk_full.bak'
    WITH MOVE N'm_bk' TO N'/var/opt/mssql/data/m_bk_r2.mdf',
         MOVE N'm_bk_log' TO N'/var/opt/mssql/data/m_bk_r2_log.ldf', KEEP_CDC, RECOVERY;
GO
RESTORE DATABASE m_bk_r3 FROM DISK = N'/var/opt/mssql/data/m_bk_full.bak'
    WITH MOVE N'm_bk' TO N'/var/opt/mssql/data/m_bk_r3.mdf',
         MOVE N'm_bk_log' TO N'/var/opt/mssql/data/m_bk_r3_log.ldf', NORECOVERY;
GO
DECLARE @t DATETIME;
SELECT @t = mark_time FROM m_bk.dbo.run_marks WHERE mark_name = 'before_erasure';
RESTORE LOG m_bk_r3 FROM DISK = N'/var/opt/mssql/data/m_bk_log.trn' WITH STOPAT = @t, RECOVERY;
GO
RESTORE DATABASE m_bk_r4 FROM DISK = N'/var/opt/mssql/data/m_bk_full.bak'
    WITH MOVE N'm_bk' TO N'/var/opt/mssql/data/m_bk_r4.mdf',
         MOVE N'm_bk_log' TO N'/var/opt/mssql/data/m_bk_r4_log.ldf', NORECOVERY;
GO
RESTORE LOG m_bk_r4 FROM DISK = N'/var/opt/mssql/data/m_bk_log.trn' WITH RECOVERY;
GO
CREATE TABLE #r (seq VARCHAR(30), db SYSNAME, subject_present INT, ct_exists INT, ct_rows_42 INT);
INSERT #r (seq, db) VALUES ('R1_full_default', 'm_bk_r1'), ('R2_full_keep_cdc', 'm_bk_r2'),
                           ('R3_full_log_stopat', 'm_bk_r3'), ('R4_full_log_end', 'm_bk_r4');
DECLARE @db SYSNAME, @sql NVARCHAR(MAX);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT db FROM #r;
OPEN c;
FETCH NEXT FROM c INTO @db;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'UPDATE #r SET subject_present = (SELECT COUNT(*) FROM ' + QUOTENAME(@db)
             + N'.dbo.customer WHERE customer_id = 42) WHERE db = ''' + @db + N''';';
    EXEC (@sql);
    UPDATE #r SET ct_exists = CASE WHEN OBJECT_ID(@db + '.cdc.dbo_customer_CT') IS NULL THEN 0 ELSE 1 END
    WHERE db = @db;
    IF OBJECT_ID(@db + '.cdc.dbo_customer_CT') IS NOT NULL
    BEGIN
        SET @sql = N'UPDATE #r SET ct_rows_42 = (SELECT COUNT(*) FROM ' + QUOTENAME(@db)
                 + N'.cdc.dbo_customer_CT WHERE customer_id = 42) WHERE db = ''' + @db + N''';';
        EXEC (@sql);
    END
    FETCH NEXT FROM c INTO @db;
END
CLOSE c; DEALLOCATE c;
SELECT CONCAT('RESULT,', $(TRIAL), ',', r.seq, ',', r.subject_present, ',', d.is_cdc_enabled, ',',
              r.ct_exists, ',', ISNULL(r.ct_rows_42, 0), ',',
              (SELECT COUNT(*) FROM msdb.dbo.cdc_jobs j WHERE j.database_id = d.database_id), ',',
              d.is_temporal_history_retention_enabled)
FROM #r r JOIN sys.databases d ON d.name = r.db
ORDER BY r.seq;
GO
