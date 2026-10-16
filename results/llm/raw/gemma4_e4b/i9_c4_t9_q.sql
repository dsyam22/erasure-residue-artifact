SELECT 
    t.name AS TableName, 
    s.name AS SchemaName 
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY SchemaName, TableName;

SELECT 
    c.name AS ColumnName, 
    ty.name AS DataType, 
    c.max_length AS MaxLength, 
    c.is_nullable AS IsNullable
FROM sys.columns c
JOIN sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE SCHEMA_NAME(c.schema_id) = 'dbo' AND OBJECT_NAME(c.object_id) = 'customer';

SELECT 
    fk.name AS ForeignKeyName, 
    OBJECT_NAME(fk.parent_object_id) AS TableHoldingForeignID, 
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ForeignColumnName, 
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable, 
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) <> 'customer' 
AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = fkc.referenced_object_id AND name = 'customer_id');
