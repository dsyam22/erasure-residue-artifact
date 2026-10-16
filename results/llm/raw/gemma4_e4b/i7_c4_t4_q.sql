-- Inspecting the database structure and relevant tables/columns
SELECT
    t.name AS TableName,
    s.name AS SchemaName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.name IN ('customer', 'customer_replica') OR t.schema_name = 'reporting';

-- Checking indexes and constraints on the relevant tables to see potential linkages
SELECT
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
    fk.name AS ConstraintName,
    OBJECT_DEFINITION(fk.object_id) AS Definition
FROM 
    sys.foreign_keys fk
INNER JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE 
    OBJECT_NAME(fk.parent_object_id) IN ('customer', 'customer_replica');

-- Listing all user views and stored procedures that might interact with customer data (looking for keywords)
SELECT
    o.name AS ObjectName,
    o.type_desc AS ObjectType,
    OBJECT_DEFINITION(o.object_id) AS DefinitionSnippet
FROM 
    sys.objects o
WHERE 
    o.type IN ('V', 'P') -- Views and Stored Procedures
    AND OBJECT_DEFINITION(o.object_id) LIKE '%customer%' 
ORDER BY
    ObjectType, ObjectName;
