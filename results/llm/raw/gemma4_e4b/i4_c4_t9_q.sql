SELECT 
    t.name AS table_name, 
    c.name AS column_name, 
    ty.name AS data_type, 
    c.max_length / 2 AS max_bytes
FROM 
    sys.tables t
JOIN 
    sys.columns c ON t.object_id = c.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.name IN ('customer', 'member')
ORDER BY 
    t.name, c.column_id;

SELECT 
    i.name AS index_name, 
    OBJECT_NAME(i.object_id) AS table_name, 
    COL_NAME(i.object_id, i.index_id) AS column_name, 
    CASE WHEN i.is_primary_key = 1 THEN 'PK' ELSE '' END + 
    CASE WHEN i.is_unique_constraint = 1 THEN 'UQ' ELSE '' END AS constraint_type
FROM 
    sys.indexes i
JOIN 
    sys.objects o ON i.object_id = o.object_id
WHERE 
    o.name IN ('customer', 'member')
ORDER BY 
    table_name, index_name;
