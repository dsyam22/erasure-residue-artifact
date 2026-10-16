-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar', 'varchar', 'char', 'nchar', 'text', 'ntext')
  AND c.max_length >= 10
  AND t.name NOT IN ('customer', 'customer_history')
ORDER BY t.name, c.name;
