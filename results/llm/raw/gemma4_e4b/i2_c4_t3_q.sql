SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM 
    sys.tables t (N'dbo') -- Focus on the dbo schema
JOIN 
    sys.columns c ON t.object_id = c.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.name IN (SELECT name FROM sys.tables) -- Check all tables in dbo
ORDER BY 
    TableName, ColumnName;

-- Check for Foreign Key Constraints to identify relationships referencing customer data
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS ReferencingTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ReferencingColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM 
    sys.foreign_keys fk
JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id;

-- Check for any triggers that might run on the customer table deletion (potential unintended logging/auditing)
SELECT 
    t.name AS TriggerName,
    OBJECT_SCHEMA_NAME(t.parent_object_id) AS SchemaName,
    OBJECT_NAME(t.parent_object_id) AS TableAffected
FROM 
    sys.objects t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.type = 'TR' 
AND 
    s.name = 'dbo';
