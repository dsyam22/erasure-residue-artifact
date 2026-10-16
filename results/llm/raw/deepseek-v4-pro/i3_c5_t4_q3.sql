-- QUERY
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name LIKE '%customer%' OR t.name LIKE '%member%'
ORDER BY s.name, t.name;
