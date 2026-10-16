SELECT 
    t.name AS SchemaName, 
    t.name AS TableName, 
    c.name AS ColumnName, 
    ty.name AS DataType, 
    c.max_length AS MaxLength
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.name IN ('customer', 'customer_replica')
    AND s.name IN ('dbo', 'reporting')

UNION ALL

SELECT 
    'Foreign Key Check' AS SchemaName, 
    OBJECT_NAME(fkc.parent_object_id) AS TableName, 
    COL_NAME(fkc.constrained_columns, fkc.parent_object_id, fkc.constrained_column_id) AS ColumnName, 
    'INT' AS DataType, 
    NULL AS MaxLength
FROM 
    sys.foreign_keysfk ckc
INNER JOIN 
    sys.tables t ON ckc.referenced_object_id = t.object_id
WHERE 
    OBJECT_NAME(ckc.parent_object_id) IN ('customer', 'customer_replica')

ORDER BY SchemaName, TableName, ColumnName;
