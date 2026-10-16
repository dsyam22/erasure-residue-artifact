-- 1. Candidate columns: character/XML/JSON-capable columns and any column whose name suggests personal data
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
   OR c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
   OR c.name LIKE '%addr%' OR c.name LIKE '%cust%' OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%' OR c.name LIKE '%user%'
ORDER BY s.name, t.name, c.column_id;

-- 2. Row counts per table (from partition stats, no table scans)
SELECT s.name AS schema_name,
       t.name AS table_name,
       SUM(p.rows) AS approx_row_count,
       t.temporal_type_desc,
       t.is_tracked_by_cdc,
       CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
LEFT JOIN sys.change_tracking_tables ctt ON ctt.object_id = t.object_id
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, ctt.object_id
ORDER BY s.name, t.name;

-- 3. Temporal history and CDC capture tables (may retain deleted rows)
SELECT s.name AS schema_name, t.name AS table_name, t.temporal_type_desc,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.temporal_type > 0
UNION ALL
SELECT cs.name, ct.name, 'CDC_CAPTURE_INSTANCE', NULL, ct.name
FROM cdc.change_tables cdc_t
JOIN sys.tables ct ON ct.object_id = cdc_t.object_id
JOIN sys.schemas cs ON cs.schema_id = ct.schema_id;

-- 4. Triggers and modules that might copy or log data
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       OBJECT_NAME(o.parent_object_id) AS parent_table
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('TR','P','FN','IF','TF','V')
ORDER BY o.type_desc, s.name, o.name;

-- 5. Full-text indexes (catalog content can hold deleted text until repopulated)
SELECT OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
       OBJECT_NAME(fi.object_id) AS table_name,
       fi.is_enabled,
       fi.change_tracking_state_desc
FROM sys.fulltext_indexes fi;

-- 6. Literal search for the erased values in sys.sql_modules definitions and column defaults
SELECT OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
       OBJECT_NAME(m.object_id) AS object_name
FROM sys.sql_modules m
WHERE m.definition LIKE '%subject42%'
   OR m.definition LIKE '%Subject_0000042%'
   OR m.definition LIKE '%555-0000042%';

-- 7. Database-level backup and recovery context
SELECT name, recovery_model_desc, is_cdc_enabled, is_temporal_history_retention_enabled
FROM sys.databases
WHERE name = DB_NAME();
