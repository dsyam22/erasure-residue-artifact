-- QUERY
SELECT c.name AS table_name, col.name AS column_name, t.name AS data_type
FROM sys.columns col
JOIN sys.tables c ON col.object_id = c.object_id
JOIN sys.types t ON col.user_type_id = t.user_type_id
WHERE c.name = 'customer'
ORDER BY col.column_id;
