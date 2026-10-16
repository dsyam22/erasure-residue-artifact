-- QUERY
SELECT c.name AS column_name, t.name AS table_name, ty.name AS type_name
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('customer', 'member')
ORDER BY t.name, c.column_id;
