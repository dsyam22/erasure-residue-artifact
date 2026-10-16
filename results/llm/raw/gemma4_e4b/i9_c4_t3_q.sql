SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    ISNULL(c.is_nullable, 'N/A') AS IsNullable
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_name = 'dbo'
ORDER BY 
    TableName, 
    c.column_id;
