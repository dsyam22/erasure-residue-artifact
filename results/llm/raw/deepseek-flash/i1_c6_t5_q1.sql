-- QUERY
SELECT TOP 5 o.name AS object_name, c.name AS column_name, t.name AS data_type
FROM sys.objects o
JOIN sys.columns c ON c.object_id = o.object_id
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE o.type IN ('U','V')
ORDER BY o.name, c.column_id;
