SELECT 
    t.name AS table_name,
    s.name AS schema_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE s.name IN ('dbo', 'reporting')
ORDER BY s.name, t.name, c.column_id;
