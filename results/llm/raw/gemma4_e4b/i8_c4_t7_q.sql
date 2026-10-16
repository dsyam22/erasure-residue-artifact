SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    ISNULL(c.is_nullable, CAST('N/A' AS varchar)) AS IsNullable
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_id = SCHEMA_ID('dbo') -- Focus on the dbo schema
ORDER BY 
    TableName, ColumnName;

SELECT 
    OBJECT_NAME(fk.constraint_object_id) AS ForeignKeyTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ParentColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM 
    sys.foreign_keys fk
INNER JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE 
    OBJECTPROPERTY(fk.parent_object_id, 'IsUserTable') = 1;
