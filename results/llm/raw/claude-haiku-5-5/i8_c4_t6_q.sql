SET NOCOUNT ON;

-- 1. Database context and feature flags
SELECT DB_NAME() AS database_name,
       SERVERPROPERTY('ProductVersion') AS product_version,
       d.is_cdc_enabled,
       d.is_change_tracking_enabled
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

-- 2. All user tables with row counts and special-retention flags
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.is_ledger_table,
       t.is_tracked_by_cdc,
       t.is_memory_optimized,
       SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions AS p ON p.object_id = t.object_id
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_ledger_table,
         t.is_tracked_by_cdc, t.is_memory_optimized
ORDER BY s.name, t.name;

-- 3. Character/LOB columns that could hold personal data (all tables)
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
   OR c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
   OR c.name LIKE '%cust%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%'
ORDER BY s.name, t.name, c.column_id;

-- 4. Foreign keys referencing or referenced by dbo.customer
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc
FROM sys.foreign_keys AS fk
WHERE fk.referenced_object_id = OBJECT_ID('dbo.customer')
   OR fk.parent_object_id = OBJECT_ID('dbo.customer');

-- 5. Views, procedures, functions, triggers whose definitions mention customer or the subject's identifiers
SELECT o.type_desc,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%subject42%'
   OR m.definition LIKE '%Subject_0000042%'
   OR m.definition LIKE '%555-0000042%'
ORDER BY o.type_desc, o.name;

-- 6. Non-clustered indexes on dbo.customer (erased values may persist in index pages until rebuilt)
SELECT i.name AS index_name, i.type_desc, i.is_primary_key, i.is_unique
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID('dbo.customer');

-- 7. Tables that exist in the database with names suggesting audit/log/history/backup copies
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.name LIKE '%audit%' OR t.name LIKE '%log%' OR t.name LIKE '%hist%'
   OR t.name LIKE '%backup%' OR t.name LIKE '%archive%' OR t.name LIKE '%staging%'
   OR t.name LIKE '%temp%' OR t.name LIKE '%export%' OR t.name LIKE '%customer%'
ORDER BY s.name, t.name;
