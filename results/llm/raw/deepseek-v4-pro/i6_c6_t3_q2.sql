-- QUERY
SELECT c.name AS table_name, t.name AS table_schema
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name = 'phone';
