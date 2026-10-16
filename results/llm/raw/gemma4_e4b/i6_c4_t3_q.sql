SELECT 
    t.name AS TableName, 
    c.name AS ColumnName, 
    ty.name AS DataType 
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE SCHEMA_NAME(t.schema_id) = 'dbo'
ORDER BY TableName, c.column_id;

SELECT 
    customer_id, 
    full_name, 
    email 
FROM dbo.customer 
WHERE customer_id = 42;
