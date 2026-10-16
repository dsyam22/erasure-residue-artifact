SELECT 
    t.name AS TableName, 
    s.name AS SchemaName,
    c.name AS ColumnName,
    ty.name AS DataType,
    is_nullable
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
JOIN 
    sys.columns c ON t.object_id = c.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    s.name NOT IN ('sys', 'INFORMATION_SCHEMA') -- Filter out system schemas for cleaner output
ORDER BY 
    SchemaName, TableName, ColumnPosition;

SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn
FROM 
    sys.foreign_keys fk
JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY 
    ChildTable, ParentTable;
