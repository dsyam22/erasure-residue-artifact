-- Read-only inspection batch (SELECT only)

-- 1. Database context and version
SELECT DB_NAME() AS database_name, @@VERSION AS server_version;

-- 2. All user tables with row counts and temporal / CDC / change tracking status
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       CASE WHEN ctt.object_id IS NULL THEN 0 ELSE 1 END AS change_tracking_enabled,
       t.is_memory_optimized,
       SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ctt ON ctt.object_id = t.object_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, ctt.object_id, t.is_memory_optimized
ORDER BY s.name, t.name;

-- 3. Columns that could hold personal data or the customer key
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND (c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%customer%' OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%' OR c.name LIKE '%contact%'
       OR c.name LIKE '%addr%' OR c.name LIKE '%valid_%')
ORDER BY s.name, t.name, c.column_id;

-- 4. Foreign keys that reference or are referenced by dbo.customer
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID('dbo.customer')
   OR fk.parent_object_id = OBJECT_ID('dbo.customer');

-- 5. Modules (triggers, procedures, views, functions) that mention customer or PII terms
SELECT o.type_desc,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%full_name%'
ORDER BY o.type_desc, o.name;

-- 6. Full-text indexes and their tables (text copies may persist in indexes)
SELECT OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
       OBJECT_NAME(fti.object_id) AS table_name,
       fti.is_enabled
FROM sys.fulltext_indexes fti;

-- 7. Triggers defined on dbo.customer
SELECT tr.name AS trigger_name,
       tr.is_disabled,
       tr.is_instead_of_trigger
FROM sys.triggers tr
WHERE tr.parent_id = OBJECT_ID('dbo.customer');

-- 8. Non-clustered indexes on dbo.customer (deleted values can linger in index pages until rebuilt)
SELECT i.name AS index_name,
       i.type_desc,
       i.is_primary_key,
       i.is_unique
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.customer');
