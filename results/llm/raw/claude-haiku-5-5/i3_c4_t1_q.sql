-- 1. All user tables with row counts and temporal / CDC / change tracking settings
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    CASE WHEN ct.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
    SUM(p.rows) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, ct.object_id
ORDER BY s.name, t.name;

-- 2. Columns across the database whose names suggest personal data
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND (c.name LIKE '%name%' OR c.name LIKE '%email%' OR c.name LIKE '%mail%'
       OR c.name LIKE '%phone%' OR c.name LIKE '%tel%' OR c.name LIKE '%customer%'
       OR c.name LIKE '%member%' OR c.name LIKE '%id%' OR c.name LIKE '%addr%'
       OR c.name LIKE '%note%' OR c.name LIKE '%comment%' OR c.name LIKE '%json%'
       OR ty.name IN ('xml','text','ntext','image','sql_variant'))
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys that reference or are referenced by dbo.customer or dbo.member
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
   OR fk.parent_object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'));

-- 4. Views, procedures, triggers, and functions (possible copies or logging of personal data)
SELECT o.type_desc, s.name AS schema_name, o.name AS object_name
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('V','P','TR','FN','IF','TF')
  AND o.is_ms_shipped = 0
ORDER BY o.type_desc, o.name;

-- 5. Full-text indexes and columns covered by them
SELECT
    OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
    OBJECT_NAME(fi.object_id) AS table_name,
    c.name AS indexed_column
FROM sys.fulltext_indexes fi
JOIN sys.fulltext_index_columns fic ON fic.object_id = fi.object_id
JOIN sys.columns c ON c.object_id = fic.object_id AND c.column_id = fic.column_id;

-- 6. Non-clustered indexes on the affected tables (deleted rows can linger in index pages until maintenance)
SELECT
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_primary_key,
    i.is_unique
FROM sys.indexes i
WHERE i.object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
  AND i.name IS NOT NULL;
