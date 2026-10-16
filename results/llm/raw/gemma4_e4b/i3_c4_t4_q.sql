SELECT 
    t.name AS TableName, 
    c.name AS ColumnName, 
    ty.name AS DataType, 
    c.max_length AS MaxLength
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE SCHEMA_NAME(t.schema_id) = 'dbo'
ORDER BY TableName, c.column_id;

-- Check for foreign key relationships involving the customer or member IDs to see if other tables retain links
SELECT 
    fk.name AS ForeignKeyConstraint, 
    OBJECT_NAME(fk.parent_object_id) AS ParentTable, 
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ParentColumn, 
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable, 
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) IN ('customer', 'member') 
   OR OBJECT_NAME(fk.referenced_object_id) IN ('customer', 'member');

-- Inspect trigger definitions for any logic that might write PII data to audit/log tables (if they exist)
SELECT 
    s.name AS SchemaName, 
    t.name AS TableName, 
    tr.name AS TriggerName, 
    OBJECT_DEFINITION(tr.object_id) AS TriggerDefinition
FROM sys.triggers tr
JOIN sys.objects t ON tr.parent_object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id;
