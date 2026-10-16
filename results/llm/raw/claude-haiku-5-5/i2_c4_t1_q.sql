SET NOCOUNT ON;

-- 1) Database-level settings relevant to retained copies of data
SELECT
    DB_NAME() AS database_name,
    d.is_cdc_enabled,
    ctd.database_id AS change_tracking_db_id,
    d.recovery_model_desc,
    SERVERPROPERTY('ProductVersion') AS product_version
FROM sys.databases AS d
LEFT JOIN sys.change_tracking_databases AS ctd
    ON ctd.database_id = d.database_id
WHERE d.name = DB_NAME();

-- 2) All user tables: temporal/history linkage, CDC, change tracking, memory-optimized, row counts
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
    t.is_memory_optimized,
    t.is_ms_shipped,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ctt
    ON ctt.object_id = t.object_id
LEFT JOIN sys.partitions AS p
    ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, ctt.object_id, t.is_memory_optimized, t.is_ms_shipped
ORDER BY s.name, t.name;

-- 3) Candidate PII-bearing columns: character, binary, XML, or LOB columns in all user tables and views
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns AS c
JOIN sys.objects AS o
    ON o.object_id = c.object_id
JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
WHERE o.type IN ('U','V')
  AND o.is_ms_shipped = 0
  AND (
        ty.name IN ('char','varchar','nchar','nvarchar','text','ntext',
                    'binary','varbinary','image','xml')
     OR c.name LIKE '%name%'
     OR c.name LIKE '%mail%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%customer%'
     OR c.name LIKE '%subject%'
     OR c.name LIKE '%person%'
  )
ORDER BY s.name, o.name, c.column_id;

-- 4) Objects whose names suggest copies: history, audit, log, archive, staging, backup, temp, cache, export
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V','P','FN','IF','TF','TR')
  AND (   o.name LIKE '%hist%'
       OR o.name LIKE '%audit%'
       OR o.name LIKE '%log%'
       OR o.name LIKE '%archiv%'
       OR o.name LIKE '%stag%'
       OR o.name LIKE '%backup%'
       OR o.name LIKE '%bak%'
       OR o.name LIKE '%temp%'
       OR o.name LIKE '%cache%'
       OR o.name LIKE '%export%'
       OR o.name LIKE '%customer%' )
ORDER BY s.name, o.name;

-- 5) Full-text, and any stored procedures or triggers that reference the customer table (possible copy paths)
SELECT
    'module' AS item_kind,
    OBJECT_SCHEMA_NAME(m.object_id) + '.' + OBJECT_NAME(m.object_id) AS item_name,
    o.type_desc
FROM sys.sql_modules AS m
JOIN sys.objects AS o
    ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
UNION ALL
SELECT
    'fulltext_catalog',
    ftc.name,
    'FULLTEXT_CATALOG'
FROM sys.fulltext_catalogs AS ftc;
