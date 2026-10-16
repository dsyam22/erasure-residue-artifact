SET NOCOUNT ON;

-- 1. All user tables with row counts, temporal/CDC/change-tracking settings
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.history_table_id,
    t.is_tracked_by_cdc,
    CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS is_change_tracked,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
LEFT JOIN sys.change_tracking_tables ctt ON ctt.object_id = t.object_id
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END
ORDER BY s.name, t.name;

-- 2. Character and LOB columns in every table and view (candidates for holding name/email/phone)
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE o.type IN ('U','V')
  AND ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
ORDER BY s.name, o.name, c.column_id;

-- 3. Objects whose names suggest copies, history, audit, logs, staging, or backups
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('U','V','P','FN','IF','TF')
  AND (o.name LIKE '%hist%' OR o.name LIKE '%audit%' OR o.name LIKE '%log%'
       OR o.name LIKE '%stag%' OR o.name LIKE '%bak%' OR o.name LIKE '%backup%'
       OR o.name LIKE '%cust%' OR o.name LIKE '%member%' OR o.name LIKE '%temp%'
       OR o.name LIKE '%archive%' OR o.name LIKE '%export%' OR o.name LIKE '%cdc%')
ORDER BY s.name, o.name;

-- 4. Module definitions that reference customer or member (possible hard-coded copies or logging)
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%' OR m.definition LIKE '%member%'
ORDER BY s.name, o.name;

-- 5. Foreign keys that reference dbo.customer or dbo.member (dependent copies)
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS referenced_table
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.referenced_object_id) IN ('customer','member')
   OR OBJECT_NAME(fk.parent_object_id) IN ('customer','member');
