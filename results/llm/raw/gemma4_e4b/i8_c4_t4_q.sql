SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length / 2 AS MaxLengthBytes
FROM 
    sys.columns c
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
JOIN 
    sys.tables t ON c.object_id = t.object_id
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
ORDER BY 
    SchemaName, TableName, c.column_id;
