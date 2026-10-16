-- 09_check_temporal_after_24h.sql
-- Follow-up to 07: run at least 24 hours after 07, with the container running.
-- Has the 1 DAY retention policy removed subject 42 from the history table?
SET NOCOUNT ON;
GO
USE erasure_lab;
GO

PRINT '--- Check timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS checked_at_utc;

PRINT '--- Retention configuration ---';
SELECT name, history_retention_period, history_retention_period_unit_desc
FROM sys.tables WHERE name = 'member';

PRINT '--- Subject 42: direct read of the history table ---';
SELECT member_id, full_name, email, phone, valid_from, valid_to
FROM dbo.member_history WHERE member_id = 42;

PRINT '--- Subject 42: time-travel query on the source table ---';
SELECT member_id, full_name, email, phone, valid_from, valid_to
FROM dbo.member FOR SYSTEM_TIME ALL WHERE member_id = 42;

PRINT '--- Total history rows ---';
SELECT COUNT(*) AS history_rows FROM dbo.member_history;
GO
