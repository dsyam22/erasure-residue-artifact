SET NOCOUNT ON;

-- 1. Basic database context
SELECT DB_NAME() AS database_name,
       @@VERSION AS server_version,
       SYSDATETIME() AS checked_at_utc;

-- 2. All user tables with approximate row counts, temporal and CDC status
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       t.is_memory_optimized,
       SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, t.is_memory_optimized
ORDER BY s.name, t.name;

-- 3. Columns that could hold personal data (by name pattern) across all tables, views and their types
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('U','V')
  AND (c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%tel%' OR c.name LIKE '%cust%' OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%' OR c.name LIKE '%user%' OR c.name LIKE '%contact%'
       OR c.name LIKE '%addr%' OR c.name LIKE '%ssn%' OR c.name LIKE '%birth%'
       OR c.name LIKE '%note%' OR c.name LIKE '%comment%' OR c.name LIKE '%json%'
       OR c.name LIKE '%payload%' OR c.name LIKE '%log%' OR c.name LIKE '%audit%')
ORDER BY s.name, o.name, c.column_id;

-- 4. Character/binary/JSON/XML columns that could contain personal data inline in free text
SELECT s.name AS schema_name,
       o.name AS object_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type = 'U'
  AND TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar','text','ntext','xml','json','varbinary')
ORDER BY s.name, o.name, c.column_id;

-- 5. Other objects whose definitions mention the customer table or personal data fields
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%full_name%'
ORDER BY s.name, o.name;

-- 6. Foreign keys referencing dbo.customer (possible copies elsewhere)
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID('dbo.customer')
   OR fk.parent_object_id = OBJECT_ID('dbo.customer');

-- 7. Full-text indexed tables (may retain deleted text until population/cleanup)
SELECT OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
       OBJECT_NAME(fti.object_id) AS table_name,
       fti.is_enabled,
       fti.change_tracking_state_desc
FROM sys.fulltext_indexes fti;

-- 8. Change tracking and CDC capture instances
SELECT OBJECT_SCHEMA_NAME(ctt.object_id) AS schema_name,
       OBJECT_NAME(ctt.object_id) AS table_name,
       ctt.is_track_columns_updated_on
FROM sys.change_tracking_tables ctt;

SELECT capture_instance,
       OBJECT_SCHEMA_NAME(source_object_id) AS source_schema,
       OBJECT_NAME(source_object_id) AS source_table,
       create_date
FROM cdc.change_tables;
