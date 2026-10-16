-- Read-only inventory of where personal data could be stored in llm_i1

-- 1. All user tables and views, with temporal/CDC/history indicators
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       t.temporal_type_desc,
       t.history_retention_period,
       t.is_tracked_by_cdc,
       t.is_memory_optimized
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.tables AS t ON t.object_id = o.object_id
WHERE o.type IN ('U', 'V') AND o.is_ms_shipped = 0
ORDER BY s.name, o.name;

-- 2. Every column in user tables/views that could hold text or identifiers
SELECT s.name AS schema_name,
       o.name AS object_name,
       c.column_id,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.columns AS c
JOIN sys.objects AS o ON o.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE o.type IN ('U', 'V') AND o.is_ms_shipped = 0
  AND (ty.name IN ('char','nchar','varchar','nvarchar','text','ntext','xml','sysname')
       OR c.name LIKE '%id%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%name%' OR c.name LIKE '%cust%' OR c.name LIKE '%subject%')
ORDER BY s.name, o.name, c.column_id;

-- 3. Row counts per user table (from partition stats)
SELECT s.name AS schema_name,
       t.name AS table_name,
       SUM(ps.row_count) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.dm_db_partition_stats AS ps
     ON ps.object_id = t.object_id AND ps.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- 4. Modules (procedures, functions, triggers, views) whose definitions mention the customer data
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%subject42%'
   OR m.definition LIKE '%Subject_%'
ORDER BY s.name, o.name;

-- 5. Foreign keys referencing dbo.customer (possible copies of customer_id elsewhere)
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
       OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
       OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys AS fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id = OBJECT_ID(N'dbo.customer');
