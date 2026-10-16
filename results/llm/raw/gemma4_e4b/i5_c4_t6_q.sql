SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length
FROM 
    sys.columns c
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
JOIN 
    sys.tables t ON c.object_id = t.object_id
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.is_ms_shipped = 0 -- Filter out system tables
ORDER BY 
    schema_name, table_name, c.column_id;
