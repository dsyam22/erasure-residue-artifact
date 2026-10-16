SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    OBJECTPROPERTY(object_id, 'IsSystemObject') AS IsSystem,
    CASE WHEN c.is_nullable = 1 THEN 'NULLABLE' ELSE 'NOT NULL' END AS Nullability
FROM 
    sys.columns c
JOIN 
    sys.tables t ON c.object_id = t.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_id = SCHEMA_ID('dbo') -- Assuming the main schema is dbo
ORDER BY 
    TableName, 
    c.column_id;

-- Additionally check for views that might proxy or replicate data structures
SELECT 
    v.name AS ViewName,
    SCHEMA_NAME(v.schema_id) AS SchemaName,
    OBJECT_DEFINITION(v.object_id) AS Definition
FROM 
    sys.views v
WHERE 
    v.schema_id = SCHEMA_ID('dbo');

-- Check for any triggers that might interact with the customer table (though this is usually handled by DML logs, it's good practice)
SELECT 
    tr.name AS TriggerName,
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    OBJECT_DEFINITION(tr.object_id) AS Definition
FROM 
    sys.triggers tr
JOIN 
    sys.tables t ON tr.parent_object_id = t.object_id
WHERE 
    t.name LIKE '%customer%';
