SELECT 
    t.name AS TableName, 
    c.name AS ColumnName, 
    ty.name AS DataType, 
    ISNULL(c.is_nullable, 'N/A') AS IsNullable
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE SCHEMA_NAME(t.schema_id) = 'dbo'
ORDER BY TableName, c.column_id;

-- Check for foreign key relationships referencing the customer table (if any other tables link to it)
SELECT 
    fk.name AS ForeignKeyConstraint,
    OBJECT_NAME(fkc.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn,
    OBJECT_NAME(fkc.parent_object_id) AS SourceTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS SourceColumn
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_SCHEMA_NAME(fkc.referenced_object_id) = 'dbo' 
AND OBJECT_NAME(fkc.referenced_object_id) = 'customer';

-- List all user-defined indexes to understand data indexing patterns
SELECT 
    t.name AS TableName, 
    i.name AS IndexName, 
    COL_NAME(ic.object_id, ic.column_id) AS IndexedColumn
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE SCHEMA_NAME(t.schema_id) = 'dbo' 
AND i.is_primary_key = 0;

-- Check for triggers that might execute logic on customer data changes (though DELETE was used, this is good practice)
SELECT 
    OBJECT_NAME(trigger_object_id) AS TriggerTable, 
    name AS TriggerName, 
    OBJECT_DEFINITION(trigger_object_id) AS TriggerCodeSnippet
FROM sys.triggers
WHERE SCHEMA_NAME(trigger_schema_id) = 'dbo'
AND OBJECT_NAME(trigger_object_id) IN ('customer');
