SET NOCOUNT ON;

-- 1. All user tables, row counts, and temporal/CDC/change-tracking status
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.history_table_id,
       t.is_tracked_by_cdc,
       CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
       t.is_memory_optimized,
       SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ctt ON ctt.object_id = t.object_id
LEFT JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, ctt.object_id, t.is_memory_optimized
ORDER BY s.name, t.name;

-- 2. All character-typed columns (candidates for holding names, emails, phones, free text)
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
ORDER BY s.name, t.name, c.column_id;

-- 3. Columns whose names suggest personal data
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
   OR c.name LIKE '%tel%' OR c.name LIKE '%cust%' OR c.name LIKE '%user%'
   OR c.name LIKE '%person%' OR c.name LIKE '%addr%' OR c.name LIKE '%subject%'
ORDER BY s.name, t.name, c.column_id;

-- 4. Foreign keys that reference or come from dbo.customer
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID('dbo.customer')
   OR fk.parent_object_id = OBJECT_ID('dbo.customer');

-- 5. Programmable objects (views, procedures, functions, triggers) that mention customer or the subject
SELECT o.type_desc,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%subject42%'
   OR m.definition LIKE '%42%'
ORDER BY o.type_desc, o.name;

-- 6. Any tables whose name suggests audit, log, history, backup, or staging copies
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.name LIKE '%audit%' OR t.name LIKE '%log%' OR t.name LIKE '%hist%'
   OR t.name LIKE '%bak%' OR t.name LIKE '%backup%' OR t.name LIKE '%stag%'
   OR t.name LIKE '%archive%' OR t.name LIKE '%tmp%' OR t.name LIKE '%temp%'
ORDER BY s.name, t.name;

-- 7. Current state of dbo.customer for the erased customer_id (should be zero rows)
SELECT COUNT(*) AS remaining_rows_for_customer_42
FROM dbo.customer
WHERE customer_id = 42;
