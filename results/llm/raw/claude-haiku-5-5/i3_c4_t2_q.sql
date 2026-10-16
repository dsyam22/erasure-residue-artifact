-- Read-only reconnaissance: where could erased personal data still live?

-- 1. All user tables with row counts, temporal/history and CDC status
SELECT 'table' AS info_type,
       s.name AS schema_name,
       t.name AS object_name,
       t.temporal_type_desc,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       t.is_memory_optimized,
       SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, t.is_memory_optimized
ORDER BY s.name, t.name;

-- 2. Columns that could hold identifiers or personal data (by name or type)
SELECT 'column' AS info_type,
       s.name AS schema_name,
       o.name AS object_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('U','V')
  AND (c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%cust%' OR c.name LIKE '%member%' OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%' OR c.name LIKE '%contact%' OR c.name LIKE '%user%'
       OR TYPE_NAME(c.user_type_id) IN ('xml','varbinary','image','text','ntext','sql_variant'))
ORDER BY s.name, o.name, c.column_id;

-- 3. Foreign keys that reference or are referenced by customer/member
SELECT 'foreign_key' AS info_type,
       OBJECT_SCHEMA_NAME(f.parent_object_id) AS child_schema,
       OBJECT_NAME(f.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(f.referenced_object_id) AS parent_schema,
       OBJECT_NAME(f.referenced_object_id) AS parent_table,
       f.name AS fk_name,
       f.delete_referential_action_desc
FROM sys.foreign_keys f
WHERE OBJECT_NAME(f.referenced_object_id) IN ('customer','member')
   OR OBJECT_NAME(f.parent_object_id) IN ('customer','member');

-- 4. Modules (views, procs, functions, triggers) whose text mentions the entities
SELECT 'module' AS info_type,
       OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
       OBJECT_NAME(m.object_id) AS object_name,
       o.type_desc,
       CASE WHEN m.definition LIKE '%email%' OR m.definition LIKE '%phone%' THEN 1 ELSE 0 END AS mentions_contact_fields
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%' OR m.definition LIKE '%member%';

-- 5. Triggers on any table (may copy data to logs or other tables)
SELECT 'trigger' AS info_type,
       OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
       OBJECT_NAME(tr.parent_id) AS table_name,
       tr.name AS trigger_name,
       tr.is_disabled
FROM sys.triggers tr
WHERE tr.is_ms_shipped = 0;

-- 6. Full-text indexes and CDC capture instances (copies of old values)
SELECT 'fulltext' AS info_type,
       OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
       OBJECT_NAME(fi.object_id) AS table_name,
       NULL AS detail
FROM sys.fulltext_indexes fi
UNION ALL
SELECT 'cdc_capture_instance',
       cs.source_schema,
       cs.source_table,
       cs.capture_instance
FROM cdc.change_tables ct
JOIN sys.schemas sch ON 1 = 1
JOIN (SELECT ct2.object_id, OBJECT_SCHEMA_NAME(ct2.source_object_id) AS source_schema,
             OBJECT_NAME(ct2.source_object_id) AS source_table,
             ct2.capture_instance
      FROM cdc.change_tables ct2) cs ON cs.object_id = ct.object_id
WHERE sch.name = 'cdc';
