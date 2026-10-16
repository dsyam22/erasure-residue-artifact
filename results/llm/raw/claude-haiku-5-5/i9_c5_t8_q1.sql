-- QUERY
SELECT s.name AS schema_name, t.name AS table_name, t.temporal_type_desc, c.name AS column_name, ty.name AS type_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.objects o ON o.object_id = t.object_id
ORDER BY s.name, t.name, c.column_id;
