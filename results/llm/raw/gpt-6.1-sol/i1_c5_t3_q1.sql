-- QUERY
SELECT s.name AS schema_name, t.name AS table_name, t.temporal_type_desc,
       t.history_table_id, t.is_memory_optimized,
       c.name AS column_name, ty.name AS data_type,
       t.is_tracked_by_cdc
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;
