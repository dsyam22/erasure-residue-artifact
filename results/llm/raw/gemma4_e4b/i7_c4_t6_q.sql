SELECT 
    t.name AS TableName,
    s.name AS SchemaName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM 
    sys.columns c
INNER JOIN 
    sys.tables t ON c.object_id = t.object_id
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.name IN ('customer', 'customer_replica') 
    OR (s.name = 'reporting' AND t.name = 'customer_replica') -- Specific check for the reporting schema table
ORDER BY 
    SchemaName, TableName, c.column_id;

SELECT * FROM sys.views WHERE name LIKE '%customer%';
