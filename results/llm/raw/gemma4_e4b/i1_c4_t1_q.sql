-- 1. List all tables in the database to understand the scope of data storage.
SELECT 
    t.name AS TableName, 
    s.name AS SchemaName 
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
ORDER BY 
    SchemaName, TableName;

-- 2. Inspect the structure of the primary table (dbo.customer) and its columns.
SELECT 
    c.name AS ColumnName, 
    ty.name AS DataType, 
    c.max_length AS MaxLength, 
    c.is_nullable AS IsNullable
FROM 
    sys.columns c
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    OBJECT_ID('dbo.customer') IS NOT NULL
ORDER BY 
    c.column_id;

-- 3. Identify all foreign key relationships referencing the customer_id in dbo.customer.
SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ReferencingTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ReferencingColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM 
    sys.foreign_keys fk
JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE 
    OBJECT_NAME(fk.referenced_object_id) = 'customer' AND OBJECT_SCHEMA_NAME(fk.referenced_object_id) = 'dbo';

-- 4. Check for any triggers on the dbo.customer table that might perform unintended data logging or auditing (potential exfiltration points).
SELECT 
    t.name AS TriggerName, 
    s.name AS SchemaName, 
    OBJECT_DEFINITION(t.object_id) AS TriggerDefinition
FROM 
    sys.triggers t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.parent_object_id = OBJECT_ID('dbo.customer');
