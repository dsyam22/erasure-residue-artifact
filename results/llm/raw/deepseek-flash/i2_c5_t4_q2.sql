-- QUERY
SELECT t.name AS table_name, c.name AS column_name, ty.name AS data_type
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.name LIKE '%customer%' OR c.name IN ('full_name','email','phone','customer_id')
ORDER BY t.name, c.column_id;
