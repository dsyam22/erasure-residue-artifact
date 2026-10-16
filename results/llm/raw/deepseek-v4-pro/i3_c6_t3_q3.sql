-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text')
  AND t.name NOT IN ('customer', 'member')
ORDER BY t.name, c.name;
