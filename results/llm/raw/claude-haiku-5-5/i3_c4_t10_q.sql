SET NOCOUNT ON;

-- 1. All user tables with temporal / CDC / memory-optimized flags and row counts
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       hs.name AS history_schema,
       ht.name AS history_table,
       t.is_tracked_by_cdc,
       t.is_memory_optimized,
       t.is_ms_shipped,
       SUM(p.rows) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht ON ht.object_id = t.history_retention_period_unit -- placeholder not used
LEFT JOIN sys.schemas hs ON 1 = 0
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, t.is_memory_optimized, t.is_ms_shipped, hs.name, ht.name
ORDER BY s.name, t.name;

-- 2. Temporal pairs (current <-> history)
SELECT s.name AS schema_name, t.name AS table_name,
       hs.name AS history_schema, ht.name AS history_table
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.tables ht ON ht.object_id = t.history_retention_period_unit * 0 + t.history_retention_period_unit
JOIN sys.schemas hs ON hs.schema_id = ht.schema_id
WHERE t.temporal_type = 2;

-- 3. Columns whose names suggest personal data or identifiers, across all tables
SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name,
       ty.name AS data_type, c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.name LIKE '%name%' OR c.name LIKE '%email%' OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%' OR c.name LIKE '%tel%' OR c.name LIKE '%customer%'
   OR c.name LIKE '%member%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%'
   OR c.name LIKE '%user%' OR c.name LIKE '%address%' OR c.name LIKE '%contact%'
ORDER BY s.name, t.name, c.column_id;

-- 4. Audit / log / history / backup-like table names
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.name LIKE '%audit%' OR t.name LIKE '%log%' OR t.name LIKE '%hist%'
   OR t.name LIKE '%bak%' OR t.name LIKE '%archive%' OR t.name LIKE '%stage%'
   OR t.name LIKE '%temp%' OR t.name LIKE '%tmp%' OR t.name LIKE '%export%'
ORDER BY s.name, t.name;

-- 5. Triggers
SELECT OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
       OBJECT_NAME(tr.parent_id) AS table_name,
       tr.name AS trigger_name, tr.is_disabled
FROM sys.triggers tr
WHERE tr.is_ms_shipped = 0;

-- 6. Views and procedures/functions whose definitions mention the subject's values or identifiers
SELECT o.type_desc, s.name AS schema_name, o.name AS object_name
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%email%' OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%full_name%' OR m.definition LIKE '%member%'
ORDER BY s.name, o.name;

-- 7. Full-text indexed tables
SELECT OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
       OBJECT_NAME(fi.object_id) AS table_name
FROM sys.fulltext_indexes fi;

-- 8. Change data capture capture instances
SELECT s.name AS schema_name, cc.capture_instance, cc.source_object_id
FROM cdc.change_tables cc
JOIN sys.schemas s ON 1 = 0;
