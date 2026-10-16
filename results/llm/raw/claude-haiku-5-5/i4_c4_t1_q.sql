SET NOCOUNT ON;

-- 1. All user tables with temporal, CDC, change tracking, memory-optimized and approximate row counts
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ctt ON ctt.object_id = t.object_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, t.is_memory_optimized, ctt.object_id
ORDER BY s.name, t.name;

-- 2. Columns that could hold identity or contact data, or look like keys to these subjects
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','varbinary','binary','image','sql_variant')
   OR c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%cust%'
   OR c.name LIKE '%member%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
   OR c.name LIKE '%contact%'
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys that reference or are referenced by dbo.customer or dbo.member
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
   OR fk.parent_object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'));

-- 4. Programmable objects (views, procedures, functions, triggers) whose text mentions the erased values or the affected tables
SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id) AS object_name,
    o.type_desc,
    CASE WHEN m.definition LIKE '%subject42%' OR m.definition LIKE '%555-0000042%'
         OR m.definition LIKE '%Subject_0000042%' THEN 'literal_found' ELSE 'table_ref_only' END AS match_type
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%member%'
   OR m.definition LIKE '%subject42%'
   OR m.definition LIKE '%555-0000042%'
   OR m.definition LIKE '%Subject_0000042%'
ORDER BY schema_name, object_name;

-- 5. Full-text indexes and triggers on the two tables
SELECT 'fulltext' AS kind, OBJECT_SCHEMA_NAME(fi.object_id) + '.' + OBJECT_NAME(fi.object_id) AS object_name, NULL AS detail
FROM sys.fulltext_indexes fi
WHERE fi.object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
UNION ALL
SELECT 'trigger', OBJECT_SCHEMA_NAME(tr.parent_id) + '.' + OBJECT_NAME(tr.parent_id), tr.name
FROM sys.triggers tr
WHERE tr.parent_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
   OR tr.parent_class_desc = 'DATABASE';
