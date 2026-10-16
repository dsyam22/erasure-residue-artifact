SET NOCOUNT ON;

-- 1. Database-level settings relevant to residual data
SELECT 'database_info' AS section,
       DB_NAME() AS db_name,
       d.is_cdc_enabled,
       d.is_change_tracking_enabled AS db_change_tracking,
       d.recovery_model_desc
FROM sys.databases d
WHERE d.name = DB_NAME();

-- 2. All user tables with schema, temporal/history/CDC/change-tracking flags, and row counts
SELECT 'tables' AS section,
       s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       t.temporal_type_desc,
       hs.name AS history_schema,
       ht.name AS history_table,
       t.is_tracked_by_cdc,
       ct.object_id AS change_tracking_enabled,
       SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, hs.name, ht.name,
         t.is_tracked_by_cdc, ct.object_id
ORDER BY s.name, t.name;

-- 3. Columns that could hold personal data (by name or type), across all tables
SELECT 'candidate_columns' AS section,
       s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND (c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%tel%' OR c.name LIKE '%cust%' OR c.name LIKE '%member%'
       OR c.name LIKE '%subject%' OR c.name LIKE '%person%' OR c.name LIKE '%user%'
       OR c.name LIKE '%ssn%' OR c.name LIKE '%addr%' OR c.name LIKE '%note%'
       OR c.name LIKE '%json%' OR c.name LIKE '%text%' OR c.name LIKE '%desc%'
       OR TYPE_NAME(c.user_type_id) IN ('xml','text','ntext','sql_variant'))
ORDER BY s.name, t.name, c.column_id;

-- 4. Foreign keys that reference customer or member (possible dependent copies)
SELECT 'foreign_keys' AS section,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc,
       fk.name AS fk_name
FROM sys.foreign_keys fk
ORDER BY parent_table, child_table;

-- 5. Views, procedures, triggers, and modules whose definitions mention the subject identifiers
SELECT 'module_text_hits' AS section,
       OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
       OBJECT_NAME(m.object_id) AS object_name,
       o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%member%' OR m.definition LIKE '%customer%'
ORDER BY schema_name, object_name;

-- 6. Full-text indexes and CDC capture instances
SELECT 'fulltext_catalogs' AS section, name, is_default FROM sys.fulltext_catalogs;
SELECT 'cdc_capture_instances' AS section,
       capture_instance, OBJECT_NAME(source_object_id) AS source_table,
       OBJECT_NAME(object_id) AS change_table
FROM cdc.change_tables;
