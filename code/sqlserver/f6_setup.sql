-- f6_setup.sql   (sqlcmd variable: RUN = 1..5)
-- Repeat of the temporal-retention measurement, one database per run: temporal_r$(RUN).
-- System-versioned table with a 1 DAY retention period, 1,000 synthetic subjects, subjects
-- 1 to 100 deleted. f6_run.sh creates five of these a few minutes apart and then polls them.
SET NOCOUNT ON;
GO
USE master;
GO
IF DB_ID('temporal_r$(RUN)') IS NOT NULL
BEGIN
    ALTER DATABASE temporal_r$(RUN) SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE temporal_r$(RUN);
END
GO
CREATE DATABASE temporal_r$(RUN);
GO
USE temporal_r$(RUN);
GO
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
CREATE TABLE dbo.run_info (erased_at DATETIME2 NOT NULL);
GO
;WITH n AS (
    SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.member (member_id, full_name, email)
SELECT i, CONCAT('Subject_', RIGHT(CONCAT('000000', i), 6)), CONCAT('subject', i, '@example.invalid')
FROM n;
GO
DELETE FROM dbo.member WHERE member_id <= 100;
INSERT dbo.run_info VALUES (SYSUTCDATETIME());
GO
SELECT CONCAT('SETUP,', $(RUN), ',', CONVERT(VARCHAR(19), erased_at, 120), ',',
              (SELECT COUNT(*) FROM dbo.member_history WHERE member_id <= 100), ',',
              (SELECT is_temporal_history_retention_enabled FROM sys.databases WHERE name = DB_NAME()))
FROM dbo.run_info;
GO
