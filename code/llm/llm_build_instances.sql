-- llm_build_instances.sql
-- Builds the nine task databases for the LLM verification study (llm_i1 .. llm_i9) and a
-- read-only login, llm_reader, that the model-written scripts run under.
-- Every database has dbo.customer with 100 synthetic subjects; the data subject is id 42:
--   full_name 'Subject_0000042', email 'subject42@example.invalid', phone '+1-555-0000042'
--
--   i1  CDC on customer; subject deleted                     -> residue: change table
--   i2  customer is temporal (history kept forever); deleted -> residue: history table
--   i3  customer has CDC, member is temporal; deleted        -> residue: change table + history
--   i4  same as i3, but erased by overwriting with UPDATE    -> residue: change table + history
--   i5  customer is temporal with 1 DAY retention; deleted   -> residue: history (hidden from
--                                                               time-travel once a day old)
--   i6  CDC on customer; phone column dropped                -> residue: phone in change table
--   i7  reporting.customer_replica holds a copy; deleted
--       from dbo.customer only                               -> residue: replica
--   i8  plain table; deleted                                 -> clean (control)
--   i9  temporal; deleted; history purged for the subject    -> clean (control)
-- Rerunnable. CDC setup takes the same lock as the measured runs, so it is safe to run
-- while they are in progress.
SET NOCOUNT ON;
GO
USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'llm_reader')
    CREATE LOGIN llm_reader WITH PASSWORD = 'Reader#2026-lab', CHECK_POLICY = OFF;
GO
EXEC master.sys.sp_getapplock @Resource = 'm_setup', @LockMode = 'Exclusive',
     @LockOwner = 'Session', @LockTimeout = 900000;
GO
DECLARE @n INT = 1, @db SYSNAME, @sql NVARCHAR(MAX);
WHILE @n <= 9
BEGIN
    SET @db = CONCAT('llm_i', @n);
    IF DB_ID(@db) IS NOT NULL
    BEGIN
        IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = @db) = 1
        BEGIN
            SET @sql = N'EXEC ' + QUOTENAME(@db) + N'.sys.sp_cdc_disable_db;';
            EXEC (@sql);
        END
        SET @sql = N'ALTER DATABASE ' + QUOTENAME(@db) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE '
                 + QUOTENAME(@db) + N';';
        EXEC (@sql);
    END
    SET @sql = N'CREATE DATABASE ' + QUOTENAME(@db) + N';';
    EXEC (@sql);
    SET @n += 1;
END
GO

-- ---------- i1: CDC, delete ----------
USE llm_i1;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL);
GO
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customer', @role_name = NULL, @supports_net_changes = 1;
GO

-- ---------- i2: temporal (infinite), delete ----------
USE llm_i2;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL, valid_to DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.customer_history));
GO

-- ---------- i3 and i4: CDC table + temporal table ----------
USE llm_i3;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL);
CREATE TABLE dbo.member (member_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL, valid_to DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.member_history));
GO
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customer', @role_name = NULL, @supports_net_changes = 1;
GO
USE llm_i4;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL);
CREATE TABLE dbo.member (member_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL, valid_to DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.member_history));
GO
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customer', @role_name = NULL, @supports_net_changes = 1;
GO

-- ---------- i5: temporal with 1 DAY retention ----------
USE llm_i5;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL, valid_to DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.customer_history, HISTORY_RETENTION_PERIOD = 1 DAY));
GO

-- ---------- i6: CDC, phone column dropped later ----------
USE llm_i6;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL);
GO
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customer', @role_name = NULL, @supports_net_changes = 1;
GO
EXEC master.sys.sp_releaseapplock @Resource = 'm_setup', @LockOwner = 'Session';
GO

-- ---------- i7: downstream replica ----------
USE llm_i7;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL);
GO
CREATE SCHEMA reporting;
GO
CREATE TABLE reporting.customer_replica (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL);
GO

-- ---------- i8: plain ----------
USE llm_i8;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL);
GO

-- ---------- i9: temporal, history purged ----------
USE llm_i9;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL, valid_to DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.customer_history));
GO

-- ---------- load 100 subjects into every database ----------
DECLARE @n INT = 1, @sql NVARCHAR(MAX), @db SYSNAME;
WHILE @n <= 9
BEGIN
    SET @db = CONCAT('llm_i', @n);
    SET @sql = N'USE ' + QUOTENAME(@db) + N';
        ;WITH n AS (SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
        INSERT dbo.customer (customer_id, full_name, email, phone)
        SELECT i, CONCAT(''Subject_'', RIGHT(CONCAT(''0000000'', i), 7)), CONCAT(''subject'', i, ''@example.invalid''),
               CONCAT(''+1-555-'', RIGHT(CONCAT(''0000000'', i), 7)) FROM n;
        IF OBJECT_ID(''dbo.member'') IS NOT NULL
            INSERT dbo.member (member_id, full_name, email, phone) SELECT customer_id, full_name, email, phone FROM dbo.customer;
        IF OBJECT_ID(''reporting.customer_replica'') IS NOT NULL
            INSERT reporting.customer_replica SELECT customer_id, full_name, email, phone FROM dbo.customer;
        CREATE USER llm_reader FOR LOGIN llm_reader;
        ALTER ROLE db_datareader ADD MEMBER llm_reader;
        GRANT VIEW DEFINITION TO llm_reader;
        IF SCHEMA_ID(''cdc'') IS NOT NULL GRANT SELECT ON SCHEMA::cdc TO llm_reader;';
    EXEC (@sql);
    SET @n += 1;
END
GO
-- wait until the capture jobs have recorded the loads
DECLARE @i INT = 0;
WHILE @i < 150 AND ((SELECT COUNT(*) FROM llm_i1.cdc.dbo_customer_CT) < 100 OR (SELECT COUNT(*) FROM llm_i3.cdc.dbo_customer_CT) < 100
                 OR (SELECT COUNT(*) FROM llm_i4.cdc.dbo_customer_CT) < 100 OR (SELECT COUNT(*) FROM llm_i6.cdc.dbo_customer_CT) < 100)
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
GO

-- ---------- the erasures ----------
DELETE FROM llm_i1.dbo.customer WHERE customer_id = 42;
DELETE FROM llm_i2.dbo.customer WHERE customer_id = 42;
DELETE FROM llm_i3.dbo.customer WHERE customer_id = 42;
DELETE FROM llm_i3.dbo.member   WHERE member_id   = 42;
UPDATE llm_i4.dbo.customer SET full_name = 'REDACTED', email = 'redacted@example.invalid', phone = NULL WHERE customer_id = 42;
UPDATE llm_i4.dbo.member   SET full_name = 'REDACTED', email = 'redacted@example.invalid', phone = NULL WHERE member_id   = 42;
DELETE FROM llm_i5.dbo.customer WHERE customer_id = 42;
DELETE FROM llm_i7.dbo.customer WHERE customer_id = 42;
DELETE FROM llm_i8.dbo.customer WHERE customer_id = 42;
DELETE FROM llm_i9.dbo.customer WHERE customer_id = 42;
GO
USE llm_i6;
GO
ALTER TABLE dbo.customer DROP COLUMN phone;
GO
USE llm_i9;
GO
ALTER TABLE dbo.customer SET (SYSTEM_VERSIONING = OFF);
GO
DELETE FROM dbo.customer_history WHERE customer_id = 42;
GO
ALTER TABLE dbo.customer SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.customer_history));
GO
USE master;
GO
-- wait until the capture jobs have recorded the erasures
DECLARE @i INT = 0;
WHILE @i < 150 AND (NOT EXISTS (SELECT 1 FROM llm_i1.cdc.dbo_customer_CT WHERE customer_id = 42 AND __$operation = 1)
                 OR NOT EXISTS (SELECT 1 FROM llm_i3.cdc.dbo_customer_CT WHERE customer_id = 42 AND __$operation = 1)
                 OR NOT EXISTS (SELECT 1 FROM llm_i4.cdc.dbo_customer_CT WHERE customer_id = 42 AND __$operation = 4))
BEGIN WAITFOR DELAY '00:00:02'; SET @i += 1; END
GO
SELECT CONCAT('BUILT,', name, ',cdc=', is_cdc_enabled, ',created=', CONVERT(VARCHAR(19), create_date, 120))
FROM sys.databases WHERE name LIKE 'llm[_]i%' ORDER BY name;
GO
