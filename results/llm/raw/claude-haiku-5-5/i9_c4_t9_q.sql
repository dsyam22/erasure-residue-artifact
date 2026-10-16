-- Read-only inventory for locating residual personal data (llm_i9)
USE llm_i9;

-- 1. Database-level change tracking / CDC status
SELECT name, is_cdc_enabled, is_tracked_by_cdc
FROM sys.databases
WHERE name = DB_NAME();

-- 2. All user tables with temporal / history relationships and approximate row counts
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       hs.name AS history_schema,
       ht.name AS history_table,
       t.is_tracked_by_cdc,
       SUM(ps.row_count) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id AND ps.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, hs.name, ht.name, t.is_tracked_by_cdc
ORDER BY s.name, t.name;

-- 3. Columns that could hold personal data (names/contact fields, customer keys)
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND (c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%customer%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%'
       OR c.name LIKE '%contact%' OR c.name LIKE '%addr%' OR c.name LIKE '%user%'
       OR c.name LIKE '%text%' OR c.name LIKE '%json%' OR c.name LIKE '%note%'
       OR c.name LIKE '%log%' OR c.name LIKE '%payload%')
ORDER BY s.name, t.name, c.column_id;

-- 4. Foreign keys referencing dbo.customer (could copy the customer_id elsewhere)
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id = OBJECT_ID(N'dbo.customer');

-- 5. Programmable objects whose definitions mention customer or the subject's identifiers
SELECT o.type_desc,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%subject42%'
   OR m.definition LIKE '%Subject_0000042%'
ORDER BY o.type_desc, o.name;

-- 6. Triggers on dbo.customer (may write copies to audit/log tables)
SELECT tr.name AS trigger_name, tr.is_disabled, OBJECT_NAME(tr.parent_id) AS on_table
FROM sys.triggers tr
WHERE tr.parent_id = OBJECT_ID(N'dbo.customer');
