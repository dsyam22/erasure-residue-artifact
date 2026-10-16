SELECT 
    t.name AS table_name, 
    c.name AS column_name, 
    ty.name AS data_type,
    c.max_length AS max_length_bytes
FROM 
    sys.columns c
JOIN 
    sys.tables t ON c.object_id = t.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    table_name, column_id;
