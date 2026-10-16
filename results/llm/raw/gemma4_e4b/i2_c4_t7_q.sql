SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLengthBytes,
    ISNULL(c.is_nullable, CAST('N/A' AS nvarchar)) AS IsNullable,
    OBJECT_DEFINITION(sc.object_id) AS SchemaDefinition -- Provides stored procedure/view code if applicable
FROM 
    sys.objects o
INNER JOIN 
    sys.tables t ON o.object_id = t.object_id AND o.type = 'U'
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
CROSS APPLY 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
LEFT JOIN 
    sys.foreign_keys fk ON t.object_id = fk.referenced_object_id
WHERE 
    t.is_ms_shipped = 0 -- Only user tables
ORDER BY 
    TableName, ColumnName;

-- Additionally, check foreign key relationships explicitly
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn
FROM 
    sys.foreign_keys fk
INNER JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id;
