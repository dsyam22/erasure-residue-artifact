SELECT 
    t.name AS TableName, 
    c.name AS ColumnName, 
    ty.name AS DataType, 
    c.max_length AS MaxLength, 
    ISNULL(c.is_nullable, 1) AS IsNullable
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_name = 'dbo'
ORDER BY 
    TableName, c.column_id;

SELECT * FROM dbo.customer WHERE customer_id = 42;
