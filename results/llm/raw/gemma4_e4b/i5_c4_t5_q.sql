SELECT 
    t.name AS TableName, 
    c.name AS ColumnName, 
    ty.name AS DataType, 
    SCHEMA_NAME(t.schema_id) AS SchemaName
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0
ORDER BY 
    TableName, ColumnName;

SELECT 
    c.name AS ConstraintName, 
    OBJECT_NAME(c.parent_object_id) AS TableName, 
    COL_NAME(c.parent_object_id, c.parent_column_id) AS ColumnAffected, 
    CASE WHEN c.type = 'PK' THEN 'Primary Key' 
         WHEN c.type = 'UQ' THEN 'Unique Constraint' 
         ELSE 'Foreign Key/Other' END AS ConstraintType
FROM 
    sys.objects c
WHERE 
    c.type IN ('PK', 'UQ', 'FK') AND OBJECT_NAME(c.parent_object_id) NOT LIKE '%sys%';
