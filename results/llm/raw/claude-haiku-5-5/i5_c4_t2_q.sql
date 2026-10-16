-- 1. All user tables with temporal / CDC / change-tracking status and row counts
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.history_table_id,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    CASE WHEN ctt.object_id IS NULL THEN 0 ELSE 1 END AS change_tracking_enabled,
    SUM(p.rows) AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ctt ON ctt.object_id = t.object_id
LEFT JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, ctt.object_id
ORDER BY s.name, t.name;

-- 2. Columns that could hold the subject's identifiers (by name or by character type)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sql_variant')
   OR c.name LIKE '%cust%'
   OR c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
   OR c.name LIKE '%user%'
ORDER BY s.name, t.name, c.column_id;

-- 3. Triggers, views, and procedures that reference customer data (possible copies/logging)
SELECT
    o.type_desc,
    s.name AS schema_name,
    o.name AS object_name
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('TR','V','P','FN','IF','TF')
  AND OBJECT_DEFINITION(o.object_id) LIKE '%customer%'
ORDER BY o.type_desc, s.name, o.name;

-- 4. Full-text indexes and sensitivity classifications, if any
SELECT
    OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
    OBJECT_NAME(fi.object_id) AS table_name
FROM sys.fulltext_indexes AS fi;

SELECT
    OBJECT_SCHEMA_NAME(sc.major_id) AS schema_name,
    OBJECT_NAME(sc.major_id) AS table_name,
    COL_NAME(sc.major_id, sc.minor_id) AS column_name,
    sc.label,
    sc.information_type
FROM sys.sensitivity_classifications AS sc;
