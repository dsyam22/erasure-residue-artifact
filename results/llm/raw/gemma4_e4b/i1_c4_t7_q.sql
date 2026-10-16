SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length / 2 AS MaxLengthInBytes -- Displaying half size for NVARCHAR/VARCHAR
FROM 
    sys.columns c
JOIN 
    sys.tables t ON c.object_id = t.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.user_type_id
WHERE 
    -- Focus on text/string data types that could hold PII
    ty.name IN ('nvarchar', 'varchar', 'char')
ORDER BY 
    TableName, ColumnName;

-- Check for foreign key relationships involving customer IDs or other potential PII linkages
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
