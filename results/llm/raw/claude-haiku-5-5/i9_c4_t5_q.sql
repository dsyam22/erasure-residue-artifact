-- Read-only inventory for erasure verification (SELECT only)
SET NOCOUNT ON;

-- 1) All user tables with approximate row counts and temporal/CDC flags
SELECT
    s.name                       AS schema_name,
    t.name                       AS table_name,
    t.temporal_type_desc,
    hs.name + '.' + ht.name      AS history_table,
    t.is_tracked_by_cdc,
    SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s          ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht     ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas hs    ON hs.schema_id = ht.schema_id
LEFT JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, hs.name, ht.name, t.is_tracked_by_cdc
ORDER BY s.name, t.name;

-- 2) Columns that could hold personal data (by name or by type)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length
FROM sys.columns c
JOIN sys.tables t   ON t.object_id = c.object_id
JOIN sys.schemas s  ON s.schema_id = t.schema_id
JOIN sys.types ty   ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND (
        c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
     OR c.name LIKE '%cust%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%'
     OR c.name LIKE '%user%' OR c.name LIKE '%addr%' OR c.name LIKE '%note%'
     OR c.name LIKE '%json%' OR c.name LIKE '%log%' OR c.name LIKE '%audit%'
     OR ty.name IN ('xml','text','ntext','image','sql_variant')
     OR (ty.name IN ('varchar','nvarchar','char','nchar') AND c.max_length = -1)
  )
ORDER BY s.name, t.name, c.column_id;

-- 3) Tables/columns whose names suggest history, audit, log, or staging copies
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND (t.name LIKE '%hist%' OR t.name LIKE '%audit%' OR t.name LIKE '%log%'
    OR t.name LIKE '%backup%' OR t.name LIKE '%bak%' OR t.name LIKE '%stag%'
    OR t.name LIKE '%archive%' OR t.name LIKE '%tmp%' OR t.name LIKE '%copy%')
ORDER BY s.name, t.name;

-- 4) Triggers and modules that reference the customer table (possible copy logic)
SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id)        AS object_name,
    o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
ORDER BY schema_name, object_name;

-- 5) Full-text indexes and change tracking, which can retain deleted text
SELECT OBJECT_SCHEMA_NAME(object_id) AS schema_name, OBJECT_NAME(object_id) AS table_name, 'fulltext' AS feature
FROM sys.fulltext_indexes
UNION ALL
SELECT OBJECT_SCHEMA_NAME(object_id), OBJECT_NAME(object_id), 'change_tracking'
FROM sys.change_tracking_tables;
