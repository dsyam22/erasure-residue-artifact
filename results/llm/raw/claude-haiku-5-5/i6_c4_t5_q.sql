-- 1. All user tables and columns, with flags for phone-like columns
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    CASE WHEN c.name LIKE '%phone%' OR c.name LIKE '%tel%' OR c.name LIKE '%mobile%' OR c.name LIKE '%msisdn%'
         THEN 1 ELSE 0 END AS is_phone_like
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;

-- 2. Row counts per user table (to see what data exists)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- 3. Objects that may hold copies of data: views, procedures, triggers, functions
SELECT
    o.type_desc,
    s.name AS schema_name,
    o.name AS object_name
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('V','P','TR','FN','IF','TF','U')
  AND o.is_ms_shipped = 0
ORDER BY o.type_desc, s.name, o.name;

-- 4. Features that retain history or copies of rows
SELECT 'Change Tracking DB' AS feature, CAST(COUNT(*) AS varchar(20)) AS detail FROM sys.change_tracking_databases WHERE database_id = DB_ID()
UNION ALL
SELECT 'Query Store enabled', CAST(actual_state_desc AS varchar(20)) FROM sys.database_query_store_options
UNION ALL
SELECT 'Temporal history tables', CAST(COUNT(*) AS varchar(20)) FROM sys.tables WHERE temporal_type = 1
UNION ALL
SELECT 'CDC-tracked tables', CAST(COUNT(*) AS varchar(20)) FROM sys.tables WHERE is_tracked_by_cdc = 1
UNION ALL
SELECT 'Full-text catalogs', CAST(COUNT(*) AS varchar(20)) FROM sys.fulltext_catalogs;
