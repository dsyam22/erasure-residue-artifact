-- QUERY
SELECT
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.name IN ('full_name','email','phone')
ORDER BY t.name, c.name;
