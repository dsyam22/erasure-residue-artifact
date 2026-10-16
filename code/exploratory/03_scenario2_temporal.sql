-- 03_scenario2_temporal.sql
-- Scenario 2: does a deleted subject's data remain in a temporal history table?
-- Rerunnable: drops and recreates dbo.member each time. Synthetic data only.
SET NOCOUNT ON;
GO
USE erasure_lab;
GO

IF OBJECT_ID('dbo.member') IS NOT NULL
BEGIN
    IF OBJECTPROPERTY(OBJECT_ID('dbo.member'), 'TableTemporalType') = 2
        ALTER TABLE dbo.member SET (SYSTEM_VERSIONING = OFF);
    DROP TABLE dbo.member;
END
GO
IF OBJECT_ID('dbo.member_history') IS NOT NULL
    DROP TABLE dbo.member_history;
GO

-- System-versioned table created the default way: no retention period given
CREATE TABLE dbo.member (
    member_id  INT           NOT NULL PRIMARY KEY,
    full_name  NVARCHAR(100) NOT NULL,
    email      NVARCHAR(200) NOT NULL,
    phone      NVARCHAR(30)  NULL,
    valid_from DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    valid_to   DATETIME2 GENERATED ALWAYS AS ROW END   NOT NULL,
    PERIOD FOR SYSTEM_TIME (valid_from, valid_to)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.member_history));
GO

;WITH n AS (
    SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.member (member_id, full_name, email, phone)
SELECT i,
       CONCAT('Subject_', RIGHT(CONCAT('000000', i), 6)),
       CONCAT('subject', i, '@example.invalid'),
       CONCAT('+1-555-', RIGHT(CONCAT('0000', i), 4))
FROM n;
GO

PRINT '--- Run timestamp (UTC) ---';
SELECT SYSUTCDATETIME() AS run_started_utc;

PRINT '--- Retention configuration (-1 = keep history forever) ---';
SELECT name, temporal_type_desc, history_retention_period, history_retention_period_unit_desc
FROM sys.tables WHERE name = 'member';
SELECT name, is_temporal_history_retention_enabled
FROM sys.databases WHERE name = 'erasure_lab';

PRINT '--- BEFORE delete ---';
SELECT COUNT(*) AS source_rows_for_subject  FROM dbo.member         WHERE member_id = 42;
SELECT COUNT(*) AS history_rows_for_subject FROM dbo.member_history WHERE member_id = 42;

PRINT '--- Erasure: DELETE subject 42 ---';
DELETE FROM dbo.member WHERE member_id = 42;

PRINT '--- AFTER delete ---';
SELECT COUNT(*) AS source_rows_for_subject FROM dbo.member WHERE member_id = 42;

PRINT '--- History table contents for subject 42 ---';
SELECT member_id, full_name, email, phone, valid_from, valid_to
FROM dbo.member_history WHERE member_id = 42;

PRINT '--- Same subject through an ordinary time-travel query on the source table ---';
SELECT member_id, full_name, email, phone
FROM dbo.member FOR SYSTEM_TIME ALL WHERE member_id = 42;
GO
