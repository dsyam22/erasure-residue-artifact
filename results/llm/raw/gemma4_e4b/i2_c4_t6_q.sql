SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    ISNULL(c.max_length, 0) AS MaxLength,
    CASE WHEN c.is_nullable = 1 THEN 'Yes' ELSE 'No' END AS IsNullable
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    TableName, ColumnName;
