SELECT 
    t.name AS TableName, 
    s.name AS SchemaName, 
    CASE WHEN t.is_ms_shipped = 1 THEN 'System' ELSE 'User' END AS Source
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name NOT LIKE 'sys%' -- Exclude system tables for cleaner output
ORDER BY SchemaName, TableName;

SELECT 
    c.name AS ColumnName, 
    ty.name AS DataType, 
    c.max_length AS MaxLength, 
    c.is_nullable AS IsNullable, 
    OBJECT_NAME(c.object_id) AS TableName
FROM sys.columns c
JOIN sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE OBJECT_NAME(c.object_id) = 'customer' -- Focus on the target table
ORDER BY TableName, c.column_id;

SELECT 
    fk.name AS ForeignKeyName, 
    OBJECT_NAME(fk.parent_object_id) AS SourceTable, 
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS SourceColumn, 
    OBJECT_NAME(fk.referenced_object_id) AS TargetTable, 
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS TargetColumn
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY SourceTable;
