SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type_name,
    c.max_length,
    c.is_nullable,
    c.is_identity,
    dc.definition AS default_constraint_definition
FROM sys.schemas s
JOIN sys.tables t ON s.schema_id = t.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
WHERE s.name IN ('dbo', 'reporting')
ORDER BY s.name, t.name, c.column_id;
