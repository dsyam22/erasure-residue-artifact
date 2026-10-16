SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM 
    sys.columns c
JOIN 
    sys.tables t ON c.object_id = t.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.user_type_id
WHERE 
    t.name = 'customer' AND SCHEMA_NAME(t.schema_id) = 'dbo'
UNION ALL
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS SourceTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS SourceColumn,
    'FK/Reference' AS DataType,
    CAST(NULL AS int) AS MaxLength,
    'No' AS IsNullable
FROM 
    sys.foreign_keys fk
JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE 
    OBJECT_NAME(fk.referenced_object_id) = 'customer';

SELECT 
    s.name AS SchemaName, 
    t.name AS TableName, 
    CASE WHEN t.is_ms_shipped = 1 THEN 'System' ELSE 'User' END AS OriginType
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
ORDER BY 
    SchemaName, TableName;

SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.customer') AND type_desc LIKE '%NONCLUSTERED%' ORDER BY name DESC;
