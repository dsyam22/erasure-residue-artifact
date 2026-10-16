SELECT 
    t.name AS TableName, 
    c.name AS ColumnName, 
    ty.name AS DataType,
    CASE WHEN c.is_nullable = 'NO' THEN 'NOT NULL' ELSE 'NULLABLE' END AS Nullability
FROM 
    sys.tables t
JOIN 
    sys.columns c ON t.object_id = c.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    TableName, ColumnName;
