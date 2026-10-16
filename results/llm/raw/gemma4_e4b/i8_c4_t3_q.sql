SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLengthBytes,
    CASE 
        WHEN t.is_ms_shipped = 0 THEN 'User Defined' 
        ELSE 'System' 
    END AS ObjectTypeStatus
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
LEFT JOIN sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE t.is_ms_shipped = 0 -- Only look at user-created tables
ORDER BY TableName, ColumnPosition;
