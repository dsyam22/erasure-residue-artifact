-- QUERY
SELECT c.name AS column_name, t.name AS table_name
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.name IN ('customer','customer_history')
ORDER BY t.name, c.column_id;
