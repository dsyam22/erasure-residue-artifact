SET NOCOUNT ON;

-- 1. All user tables with temporal/history relationships and row counts
SELECT
    s.name                                   AS schema_name,
    t.name                                   AS table_name,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id)   AS history_schema,
    OBJECT_NAME(t.history_table_id)          AS history_table,
    t.is_tracked_by_cdc,
    SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.dm_db_partition_stats AS ps ON ps.object_id = t.object_id
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id, t.is_tracked_by_cdc
ORDER BY s.name, t.name;

-- 2. Columns that could hold the subject's identifiers or contact data
SELECT
    s.name  AS schema_name,
    o.name  AS table_name,
    o.type_desc,
    c.name  AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns AS c
JOIN sys.objects AS o ON o.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U','V')
  AND (   c.name LIKE '%cust%'
       OR c.name LIKE '%name%'
       OR c.name LIKE '%mail%'
       OR c.name LIKE '%phone%'
       OR c.name LIKE '%tel%'
       OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%'
       OR c.name LIKE '%user%'
       OR c.name LIKE '%contact%'
       OR c.name LIKE '%pii%' )
ORDER BY s.name, o.name, c.column_id;

-- 3. CDC capture instances and change tracking tables (possible copies of deleted rows)
SELECT
    OBJECT_SCHEMA_NAME(ct.object_id) AS tracked_schema,
    OBJECT_NAME(ct.object_id)        AS tracked_table,
    ct.is_track_columns_updated_on
FROM sys.change_tracking_tables AS ct;

SELECT
    capture_instance,
    OBJECT_SCHEMA_NAME(source_object_id) AS source_schema,
    OBJECT_NAME(source_object_id)        AS source_table,
    object_id,
    start_lsn
FROM cdc.change_tables;

-- 4. Views and programmable objects that reference customer data (may expose or copy it)
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
ORDER BY s.name, o.name;
