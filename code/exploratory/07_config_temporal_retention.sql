-- 07_config_temporal_retention.sql
-- Configuration test for scenarios 2 and 3 (temporal history).
--   Part A: manual purge of subject 77 from the history table (versioning off, delete, on)
--   Part B: set a finite retention period (1 DAY, the smallest unit) and leave subject 42
--           in place, so 09_check_temporal_after_24h.sql can measure when it disappears.
-- Requires: 03 and 04 have been run.
SET NOCOUNT ON;
GO
USE erasure_lab;
GO

PRINT '--- Run timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS run_started_utc;

PRINT '--- BEFORE: history rows per subject ---';
SELECT member_id, COUNT(*) AS history_rows
FROM dbo.member_history WHERE member_id IN (42, 77) GROUP BY member_id;
GO

PRINT '=== PART A: manual purge of subject 77 ===';
ALTER TABLE dbo.member SET (SYSTEM_VERSIONING = OFF);
GO
DELETE FROM dbo.member_history WHERE member_id = 77;
GO

PRINT '=== PART B: re-enable versioning with a 1 DAY retention period ===';
ALTER TABLE dbo.member SET (SYSTEM_VERSIONING = ON (
    HISTORY_TABLE = dbo.member_history,
    HISTORY_RETENTION_PERIOD = 1 DAY));
GO

PRINT '--- Retention configuration now ---';
SELECT name, temporal_type_desc, history_retention_period, history_retention_period_unit_desc
FROM sys.tables WHERE name = 'member';

PRINT '--- AFTER: history rows per subject (77 should be gone, 42 still present) ---';
SELECT member_id, COUNT(*) AS history_rows
FROM dbo.member_history WHERE member_id IN (42, 77) GROUP BY member_id;

PRINT '--- Subject 77 through a time-travel query ---';
SELECT member_id, full_name, email, phone, valid_from, valid_to
FROM dbo.member FOR SYSTEM_TIME ALL WHERE member_id = 77;

PRINT '--- Subject 42 history row (note valid_to; the retention clock runs from it) ---';
SELECT member_id, full_name, email, valid_to
FROM dbo.member_history WHERE member_id = 42;
GO
