SET NOCOUNT ON;

-- 1. All user tables: temporal (history) linkage, CDC, change tracking, row counts
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
       SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ctt ON ctt.object_id = t.object_id
LEFT JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, ctt.object_id
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal data (names, contact info, identifiers, free text, JSON/XML, binary)
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND (   c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%cust%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%'
       OR c.name LIKE '%user%' OR c.name LIKE '%addr%' OR c.name LIKE '%note%'
       OR c.name LIKE '%comment%' OR c.name LIKE '%desc%' OR c.name LIKE '%json%'
       OR c.name LIKE '%xml%' OR c.name LIKE '%payload%' OR c.name LIKE '%log%'
       OR TYPE_NAME(c.user_type_id) IN ('xml','json','text','ntext','image','varbinary','sql_variant')
       OR c.name LIKE '%id' AND c.name <> 'customer_id' )
ORDER BY s.name, t.name, c.column_id;

-- 3. Triggers (could copy data to audit/log tables)
SELECT s.name AS schema_name,
       o.name AS parent_table,
       tr.name AS trigger_name,
       tr.is_disabled,
       OBJECT_DEFINITION(tr.object_id) AS trigger_definition
FROM sys.triggers tr
JOIN sys.objects o ON o.object_id = tr.parent_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE tr.is_ms_shipped = 0;

-- 4. Objects whose names suggest audit/history/log/backup/staging copies
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V','P','FN','IF','TF')
  AND (o.name LIKE '%audit%' OR o.name LIKE '%hist%' OR o.name LIKE '%log%'
       OR o.name LIKE '%bak%' OR o.name LIKE '%backup%' OR o.name LIKE '%stag%'
       OR o.name LIKE '%archive%' OR o.name LIKE '%tmp%' OR o.name LIKE '%temp%'
       OR o.name LIKE '%customer%');

-- 5. Database-level settings relevant to retention
SELECT d.name AS database_name,
       d.recovery_model_desc,
       d.is_cdc_enabled,
       d.is_change_tracking_on_for_db = CASE WHEN EXISTS (SELECT 1 FROM sys.change_tracking_databases cdb WHERE cdb.database_id = d.database_id) THEN 1 ELSE 0 END,
       d.is_temporal_history_retention_enabled
FROM sys.databases d
WHERE d.name = DB_NAME();

-- 6. Full-text indexes (could hold indexed copies of names/emails)
SELECT OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
       OBJECT_NAME(fi.object_id) AS table_name,
       fi.is_enabled
FROM sys.fulltext_indexes fi;
