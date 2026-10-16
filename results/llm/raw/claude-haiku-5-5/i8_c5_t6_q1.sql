-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       t.is_ms_shipped,
       t.temporal_type,
       t.is_memory_optimized,
       SUM(p.rows) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name, t.object_id, t.is_ms_shipped, t.temporal_type, t.is_memory_optimized
ORDER BY s.name, t.name;
