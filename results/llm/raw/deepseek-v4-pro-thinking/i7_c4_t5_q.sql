SELECT DB_NAME() AS current_database;

SELECT s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       t.temporal_type_desc,
       t.history_table_id
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;

SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       c.column_id,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length,
       c.precision,
       c.scale,
       c.is_nullable,
       c.is_identity,
       c.is_computed
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.columns c ON c.object_id = o.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE o.type IN ('U','V')
ORDER BY s.name, o.name, c.column_id;

SELECT s.name AS schema_name,
       t.name AS table_name,
       SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.dm_db_partition_stats p ON p.object_id = t.object_id
WHERE p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT s.name AS schema_name,
       v.name AS view_name,
       m.definition
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
JOIN sys.sql_modules m ON m.object_id = v.object_id
ORDER BY s.name, v.name;
