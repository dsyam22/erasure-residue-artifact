SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_identity,
    c.column_id
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0
    AND (
        c.name LIKE '%customer%' 
        OR c.name LIKE '%name%' 
        OR c.name LIKE '%email%' 
        OR c.name LIKE '%phone%'
        OR c.name LIKE '%subject%'
    )
ORDER BY s.name, t.name, c.column_id;
