-- 1. Get detailed schema information for the primary target table to confirm data types and existence.
SELECT
    c.name AS TableName,
    COL_NAME(object_id, c.column_id) AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM 
    sys.columns c
JOIN 
    sys.types ty ON c.system_type_id = ty.user_type_id
WHERE 
    OBJECT_NAME(c.object_id) = 'customer'
ORDER BY 
    c.column_id;

-- 2. Check for foreign key constraints that reference the customer_id column (potential orphaned records).
SELECT
    SCHEMA_NAME(fk.schema_id) AS ReferencingSchema,
    OBJECT_NAME(fk.parent_object_id) AS ReferencingTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ReferencingColumn,
    '-> customer_id' AS ReferencedKey,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ReferencedSchema,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable
FROM 
    sys.foreign_keys fk
JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE 
    OBJECT_NAME(fk.referenced_object_id) = 'customer';

-- 3. List all user tables in the database to ensure no other unindexed/unrelated table might hold PII.
SELECT 
    s.name AS SchemaName, 
    t.name AS TableName, 
    CASE WHEN t.is_ms_shipped = 1 THEN 'System' ELSE 'User' END AS Type;
