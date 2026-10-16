-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'customer'
ORDER BY c.column_id;
