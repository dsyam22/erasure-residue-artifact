SELECT 
    t.name AS TableName,
    s.name AS SchemaName,
    CASE WHEN t.is_ms_shipped = 1 THEN 'System' ELSE 'User' END AS SourceType,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    s.name IN ('dbo') -- Focus on the dbo schema
ORDER BY 
    TableName, ColumnName;

SELECT 
    fk.name AS ConstraintName,
    OBJECT_NAME(fk.parent_object_id) AS TableA,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnA,
    OBJECT_NAME(fk.referenced_object_id) AS TableB,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ColumnB
FROM 
    sys.foreign_keys fk
INNER JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id;
