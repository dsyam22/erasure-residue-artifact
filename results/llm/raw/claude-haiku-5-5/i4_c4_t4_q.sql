SET NOCOUNT ON;

-- 1. All user tables with row counts and temporal/CDC/ledger/memory-optimized flags
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       t.is_ledger_table,
       t.is_memory_optimized,
       SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, t.is_ledger_table, t.is_memory_optimized
ORDER BY s.name, t.name;

-- 2. Columns that are character/LOB types or have PII-like names, across all tables
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
   OR c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%' OR c.name LIKE '%member%' OR c.name LIKE '%id%'
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys (tables that may hold copies keyed to customer/member)
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc,
       fk.update_referential_action_desc
FROM sys.foreign_keys fk
ORDER BY parent_table, child_table;

-- 4. Triggers (may copy or log data on UPDATE)
SELECT OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
       OBJECT_NAME(tr.parent_id) AS table_name,
       tr.name AS trigger_name,
       tr.is_disabled,
       tr.is_instead_of_trigger,
       OBJECT_DEFINITION(tr.object_id) AS trigger_definition
FROM sys.triggers tr
WHERE tr.is_ms_shipped = 0;

-- 5. Stored procedures, views, functions whose definitions mention PII fields or the subject
SELECT o.type_desc,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%full_name%'
   OR m.definition LIKE '%customer%'
   OR m.definition LIKE '%member%'
ORDER BY o.type_desc, object_name;

-- 6. Change-data-capture and change-tracking tables
SELECT OBJECT_SCHEMA_NAME(object_id) AS schema_name, name AS table_name
FROM sys.tables
WHERE name LIKE 'cdc%' OR name LIKE 'change_tracking%' OR name LIKE '%audit%' OR name LIKE '%log%' OR name LIKE '%history%';

SELECT DB_NAME() AS database_name,
       (SELECT is_cdc_enabled FROM sys.databases WHERE database_id = DB_ID()) AS cdc_enabled,
       (SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.change_tracking_databases WHERE database_id = DB_ID()) THEN 1 ELSE 0 END) AS change_tracking_enabled,
       (SELECT is_temporal_history_retention_enabled FROM sys.databases WHERE database_id = DB_ID()) AS temporal_retention_enabled;

-- 7. Full-text indexes and columns covered
SELECT OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
       OBJECT_NAME(fti.object_id) AS table_name,
       c.name AS column_name
FROM sys.fulltext_indexes fti
JOIN sys.fulltext_index_columns fic ON fic.object_id = fti.object_id
JOIN sys.columns c ON c.object_id = fic.object_id AND c.column_id = fic.column_id;
