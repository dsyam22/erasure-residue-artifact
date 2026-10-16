-- f5_setup.sql
-- Clean measured run for F5 (temporal retention latency), in its own database temporal_run.
-- Creates a system-versioned table with a 1 DAY retention period, loads 1,000 synthetic
-- subjects and deletes subjects 1 to 100. The polling script f5_poll.sh then records, every
-- 15 minutes, how many of those 100 are still in the history table (direct read) and how
-- many a time-travel query still returns.
-- Rerunning this script restarts the measurement from zero.
SET NOCOUNT ON;
GO
USE master;
GO
IF DB_ID('temporal_run') IS NOT NULL
BEGIN
    ALTER DATABASE temporal_run SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE temporal_run;
END
GO
CREATE DATABASE temporal_run;
GO
USE temporal_run;
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
GO
PRINT '--- F5 run started ---';
SELECT SYSUTCDATETIME() AS erased_at_utc,
       DATEADD(DAY, 1, SYSUTCDATETIME()) AS eligible_for_cleanup_utc;
SELECT name, history_retention_period, history_retention_period_unit_desc
FROM sys.tables WHERE name = 'member';
SELECT is_temporal_history_retention_enabled FROM sys.databases WHERE name = 'temporal_run';
SELECT (SELECT COUNT(*) FROM dbo.member_history WHERE member_id <= 100) AS history_rows_direct,
       (SELECT COUNT(*) FROM dbo.member FOR SYSTEM_TIME ALL WHERE member_id <= 100) AS rows_via_time_travel;
GO
