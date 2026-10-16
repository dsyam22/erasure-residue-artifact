-- QUERY
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name IN ('customer_id', 'full_name', 'email', 'phone')
  AND s.name <> 'dbo'
ORDER BY s.name, t.name, c.name;
