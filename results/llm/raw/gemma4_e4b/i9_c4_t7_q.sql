SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length / 2 AS MaxLengthBytes -- Displaying half length for readability (assuming standard NCHAR/VARCHAR mapping)
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Filter out system tables
ORDER BY 
    TableName, 
    c.column_id;

SELECT * FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('dbo.customer');
