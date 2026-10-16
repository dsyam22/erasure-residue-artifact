SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length / 2 AS MaxLengthBytes
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

SELECT 
    * 
FROM 
    sys.databases 
WHERE 
    name = DB_NAME() AND database_id > 4; -- Confirm current context and check for potential linked/attached databases (though unlikely to be needed here)
