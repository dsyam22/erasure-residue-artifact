SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
JOIN 
    sys.columns c ON t.object_id = c.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id
WHERE 
    s.name NOT IN ('sys', 'INFORMATION_SCHEMA') -- Focus only on user-defined schemas
ORDER BY 
    SchemaName, TableName, c.column_id;
