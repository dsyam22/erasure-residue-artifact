-- QUERY
SELECT 
    SCHEMA_NAME(t.schema_id) + '.' + t.name AS object_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar','varchar','nchar','char','ntext','text')
ORDER BY object_name, c.column_id;
