SET NOCOUNT ON;

-- 1. All user tables with row counts and temporal/CDC/memory-optimized flags
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.is_tracked_by_cdc,
       t.is_memory_optimized,
       t.is_ms_shipped,
       SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, t.is_memory_optimized, t.is_ms_shipped
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal data (by name or by character/LOB type)
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
  AND (
        c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
     OR c.name LIKE '%cust%' OR c.name LIKE '%subject%' OR c.name LIKE '%user%'
     OR c.name LIKE '%person%' OR c.name LIKE '%note%' OR c.name LIKE '%comment%'
     OR c.name LIKE '%json%' OR c.name LIKE '%payload%' OR c.name LIKE '%log%'
     OR ty.name IN ('xml','text','ntext','image','sql_variant')
     OR (ty.name IN ('nvarchar','varchar','nchar','char') AND (c.max_length = -1 OR c.max_length >= 200))
  )
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys that point at dbo.customer (child tables may keep copies or IDs)
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id = OBJECT_ID(N'dbo.customer');

-- 4. Full-text indexes and their tables (search indexes can retain deleted text)
SELECT OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
       OBJECT_NAME(fti.object_id) AS table_name,
       fti.is_enabled
FROM sys.fulltext_indexes fti;

-- 5. Triggers and modules that mention customer or the subject values
SELECT o.type_desc,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%subject42%'
   OR m.definition LIKE '%Subject_0000042%';

-- 6. Database-level change/retention settings that may keep old row versions
SELECT name,
       is_change_tracking_on = CASE WHEN EXISTS (SELECT 1 FROM sys.change_tracking_databases ctd WHERE ctd.database_id = DB_ID()) THEN 1 ELSE 0 END,
       is_cdc_enabled,
       is_temporal_history_retention_enabled
FROM sys.databases
WHERE database_id = DB_ID();
