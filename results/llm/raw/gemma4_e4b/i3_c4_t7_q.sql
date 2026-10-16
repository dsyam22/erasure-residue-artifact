SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    CASE 
        WHEN c.name IN ('full_name', 'email', 'phone') THEN 'Potential PII'
        ELSE 'Other Data'
    END AS Classification
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    TableName, ColumnName;
