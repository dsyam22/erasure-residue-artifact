SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length / 8 AS MaxLengthBytes
FROM 
    sys.tables t
JOIN 
    sys.columns c ON t.object_id = c.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_id = SCHEMA_ID('dbo') -- Focus on the default schema for core data
ORDER BY 
    TableName, ColumnName;

SELECT 
    * FROM sys.objects WHERE type IN ('v', 'f'); -- Check for views and functions that might encapsulate or store logic/data references
