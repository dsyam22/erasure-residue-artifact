SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name, ty.name AS data_type
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.name LIKE '%customer_id%' OR c.name LIKE '%name%' OR c.name LIKE '%email%' OR c.name LIKE '%phone%'
ORDER BY schema_name, table_name, c.column_id;
