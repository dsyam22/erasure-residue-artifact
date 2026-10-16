-- QUERY
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
JOIN sys.columns c ON v.object_id = c.object_id
JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.name IN ('full_name', 'email', 'phone', 'customer_id')
ORDER BY s.name, t.name, c.column_id;
