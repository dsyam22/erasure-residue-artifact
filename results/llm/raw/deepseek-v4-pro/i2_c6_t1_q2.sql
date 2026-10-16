-- QUERY
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE c.name IN ('customer_id', 'full_name', 'email', 'phone')
  AND t.name != 'customer'
ORDER BY s.name, t.name, c.name;
