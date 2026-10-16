SELECT 
    t.name AS TableName, 
    c.name AS ColumnName, 
    ty.name AS DataType, 
    SCHEMA_NAME(t.schema_id) AS SchemaName
FROM 
    sys.tables t
JOIN 
    sys.columns c ON t.object_id = c.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    SchemaName, TableName, c.column_id;

SELECT * FROM sys.foreign_keys WHERE parent_object_id IN (SELECT object_id FROM sys.tables) AND referenced_object_id IN (SELECT object_id FROM sys.tables);
