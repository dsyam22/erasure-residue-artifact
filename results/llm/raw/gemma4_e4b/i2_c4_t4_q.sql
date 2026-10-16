SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    CASE WHEN c.is_nullable = 1 THEN 'NULL Allowed' ELSE 'NOT NULL' END AS Nullability
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    SCHEMA_NAME(t.schema_id) = 'dbo'
ORDER BY 
    TableName, c.column_id;
