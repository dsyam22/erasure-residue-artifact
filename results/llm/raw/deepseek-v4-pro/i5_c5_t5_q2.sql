-- QUERY
SELECT c.name AS table_name, col.name AS column_name, ty.name AS data_type
FROM sys.columns col
JOIN sys.tables c ON col.object_id = c.object_id
JOIN sys.types ty ON col.user_type_id = ty.user_type_id
WHERE c.name IN ('customer', 'customer_history')
ORDER BY c.name, col.column_id;
