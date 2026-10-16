-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name = 'customer'
ORDER BY c.column_id;
