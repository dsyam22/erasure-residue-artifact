-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       SUM(p.rows) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name, t.object_id
ORDER BY s.name, t.name;
