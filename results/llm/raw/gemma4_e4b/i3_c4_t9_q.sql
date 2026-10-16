SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLengthBytes
FROM 
    sys.columns c
INNER JOIN 
    sys.objects t ON c.object_id = t.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_name = 'dbo' 
    AND t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    TableName, 
    c.column_id;

SELECT TOP 10 * FROM sys.tables WHERE schema_name = 'dbo';

-- Check for any non-PII related objects or indexes that might reference the IDs
SELECT 
    s.name AS SchemaName, 
    t.name AS TableName, 
    i.name AS IndexName,
    c.name AS ColumnName
FROM 
    sys.indexes i
INNER JOIN 
    sys.tables t ON i.object_id = t.object_id
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id AND ic.column_id = c.column_id
WHERE 
    s.name = 'dbo' 
    AND t.name IN ('customer', 'member');
