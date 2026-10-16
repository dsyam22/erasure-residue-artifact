SET NOCOUNT ON;

-- 1. All user tables with row counts and special-feature flags
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.is_tracked_by_cdc,
       t.is_memory_optimized,
       SUM(p.rows) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, t.is_memory_optimized
ORDER BY s.name, t.name;

-- 2. Columns that can hold text (candidate PII stores), including identifier-like columns
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sql_variant')
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%email%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%name%'
   OR c.name LIKE '%subject%'
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys that reference or are referenced by dbo.customer
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID('dbo.customer')
   OR fk.parent_object_id = OBJECT_ID('dbo.customer');

-- 4. Triggers (may write copies of data elsewhere)
SELECT OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
       OBJECT_NAME(tr.parent_id) AS table_name,
       tr.name AS trigger_name,
       tr.is_disabled
FROM sys.triggers tr
WHERE tr.is_ms_shipped = 0;

-- 5. Change tracking and CDC configuration
SELECT DB_NAME() AS database_name,
       (SELECT COUNT(*) FROM sys.change_tracking_databases WHERE database_id = DB_ID()) AS change_tracking_db_enabled,
       (SELECT COUNT(*) FROM sys.change_tracking_tables) AS change_tracking_tables,
       (SELECT is_cdc_enabled FROM sys.databases WHERE database_id = DB_ID()) AS cdc_db_enabled;

-- 6. Full-text indexes (search catalogs can retain deleted text until repopulated)
SELECT OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
       OBJECT_NAME(fti.object_id) AS table_name,
       fti.is_enabled
FROM sys.fulltext_indexes fti;

-- 7. Non-clustered indexes on dbo.customer (deleted keys may persist in index pages until maintenance)
SELECT i.name AS index_name,
       i.type_desc,
       i.is_primary_key,
       i.is_unique
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.customer');
