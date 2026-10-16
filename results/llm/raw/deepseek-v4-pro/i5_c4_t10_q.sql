SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name = 'customer'
ORDER BY c.column_id;

SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name <> 'customer'
ORDER BY t.name, c.column_id;

SELECT 
    name AS constraint_name,
    OBJECT_NAME(parent_object_id) AS table_name,
    type_desc,
    definition
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.customer');

SELECT 
    i.name AS index_name,
    OBJECT_NAME(i.object_id) AS table_name,
    i.type_desc,
    i.is_unique,
    i.filter_definition
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.customer');
