SET NOCOUNT ON;

-- 1. Columns whose names suggest personal data, across all user tables
SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name,
       ty.name AS data_type, t.is_ms_shipped, t.temporal_type_desc
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
LEFT JOIN (SELECT object_id, temporal_type_desc FROM sys.tables) x ON x.object_id = t.object_id
WHERE c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
   OR c.name LIKE '%cust%' OR c.name LIKE '%member%' OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%' OR c.name LIKE '%contact%'
ORDER BY s.name, t.name, c.column_id;

-- 2. All user tables with temporal, CDC, and change-tracking status
SELECT s.name AS schema_name, t.name AS table_name, t.temporal_type_desc,
       t.history_retention_period, OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc, ct.object_id AS change_tracking_enabled
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

-- 3. Foreign keys referencing or referenced by the erased tables
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.referenced_object_id) IN ('customer', 'member')
   OR OBJECT_NAME(fk.parent_object_id) IN ('customer', 'member');

-- 4. Triggers on any table (may copy data into audit or log tables)
SELECT OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name, OBJECT_NAME(tr.parent_id) AS table_name,
       tr.name AS trigger_name, tr.is_disabled, OBJECT_DEFINITION(tr.object_id) AS definition
FROM sys.triggers tr
WHERE tr.is_ms_shipped = 0;

-- 5. Views, procedures, and functions whose definitions mention the erased values
SELECT o.type_desc, OBJECT_SCHEMA_NAME(o.object_id) AS schema_name, o.name
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%' OR m.definition LIKE '%member%'
   OR m.definition LIKE '%email%' OR m.definition LIKE '%phone%';

-- 6. Remaining rows in the erased tables (should be zero for the subject)
SELECT 'customer' AS tbl, COUNT(*) AS rows_total,
       SUM(CASE WHEN customer_id = 42 OR full_name LIKE '%Subject_0000042%'
                  OR email LIKE '%subject42@example.invalid%'
                  OR phone LIKE '%0000042%' THEN 1 ELSE 0 END) AS subject_matches
FROM dbo.customer
UNION ALL
SELECT 'member', COUNT(*),
       SUM(CASE WHEN member_id = 42 OR full_name LIKE '%Subject_0000042%'
                  OR email LIKE '%subject42@example.invalid%'
                  OR phone LIKE '%0000042%' THEN 1 ELSE 0 END)
FROM dbo.member;
