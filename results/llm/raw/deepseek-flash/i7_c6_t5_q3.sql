-- QUERY
SELECT t.name AS table_name, c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE c.name IN ('customer_id','full_name','email','phone')
ORDER BY s.name, t.name, c.name;
