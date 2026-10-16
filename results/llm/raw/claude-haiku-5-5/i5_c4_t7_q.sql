-- 1) All user tables with temporal / CDC / history info
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       t.temporal_type_desc,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id)        AS history_table,
       t.is_tracked_by_cdc,
       t.is_memory_optimized,
       t.is_ms_shipped
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name;

-- 2) Character / potential PII columns in all user tables
SELECT OBJECT_SCHEMA_NAME(c.object_id) AS schema_name,
       OBJECT_NAME(c.object_id)        AS table_name,
       c.column_id,
       c.name                          AS column_name,
       TYPE_NAME(c.user_type_id)       AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
WHERE TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
   OR c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
   OR c.name LIKE '%cust%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%'
ORDER BY schema_name, table_name, c.column_id;

-- 3) Row counts per table (heap/clustered only)
SELECT OBJECT_SCHEMA_NAME(ps.object_id) AS schema_name,
       OBJECT_NAME(ps.object_id)        AS table_name,
       SUM(ps.row_count)                AS row_count
FROM sys.dm_db_partition_stats AS ps
JOIN sys.tables AS t ON t.object_id = ps.object_id
WHERE ps.index_id IN (0,1)
GROUP BY ps.object_id
ORDER BY schema_name, table_name;

-- 4) Modules (views, procs, functions, triggers) that reference customer data
SELECT OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
       OBJECT_NAME(m.object_id)        AS object_name,
       o.type_desc,
       CASE WHEN m.definition LIKE '%customer%' OR m.definition LIKE '%email%'
              OR m.definition LIKE '%phone%' OR m.definition LIKE '%full_name%'
            THEN 1 ELSE 0 END          AS mentions_customer_or_pii
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
ORDER BY schema_name, object_name;

-- 5) Triggers on user tables (possible audit copies)
SELECT OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
       OBJECT_NAME(tr.parent_id)        AS parent_table,
       tr.name                          AS trigger_name,
       tr.is_disabled
FROM sys.triggers AS tr
WHERE tr.is_ms_shipped = 0;
