SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_id = SCHEMA_ID('dbo') -- Assuming the tables are in dbo schema
ORDER BY 
    TableName, ColumnName;
