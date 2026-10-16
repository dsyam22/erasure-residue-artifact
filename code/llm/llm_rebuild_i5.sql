-- llm_rebuild_i5.sql
-- Rebuilds only task database llm_i5 (temporal table, 1 DAY retention, subject 42 deleted).
-- The case is a residue case only while the deleted row is older than one day but not yet
-- physically removed, so scripts for it must be run shortly after the 24-hour mark.
SET NOCOUNT ON;
GO
USE master;
GO
IF DB_ID('llm_i5') IS NOT NULL
BEGIN
    ALTER DATABASE llm_i5 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE llm_i5;
END
GO
CREATE DATABASE llm_i5;
GO
USE llm_i5;
GO
CREATE TABLE dbo.customer (customer_id INT NOT NULL PRIMARY KEY, full_name NVARCHAR(100) NOT NULL, email NVARCHAR(200) NOT NULL, phone NVARCHAR(30) NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL, valid_to DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.customer_history, HISTORY_RETENTION_PERIOD = 1 DAY));
GO
;WITH n AS (SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
INSERT dbo.customer (customer_id, full_name, email, phone)
SELECT i, CONCAT('Subject_', RIGHT(CONCAT('0000000', i), 7)), CONCAT('subject', i, '@example.invalid'),
       CONCAT('+1-555-', RIGHT(CONCAT('0000000', i), 7)) FROM n;
CREATE USER llm_reader FOR LOGIN llm_reader;
ALTER ROLE db_datareader ADD MEMBER llm_reader;
GRANT VIEW DEFINITION TO llm_reader;
GO
DELETE FROM dbo.customer WHERE customer_id = 42;
GO
SELECT CONCAT('REBUILT llm_i5. Erased at (UTC): ', CONVERT(VARCHAR(19), SYSUTCDATETIME(), 120),
              '  Run the i5 scripts between ', CONVERT(VARCHAR(19), DATEADD(MINUTE, 1443, SYSUTCDATETIME()), 120),
              ' and ', CONVERT(VARCHAR(19), DATEADD(MINUTE, 1465, SYSUTCDATETIME()), 120), ' UTC.');
GO
