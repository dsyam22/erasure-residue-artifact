SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.user_type_id
WHERE 
    t.schema_id = SCHEMA_ID('dbo')
ORDER BY 
    TableName, ColumnName;

-- Check for foreign key constraints involving customer_id to see if other tables reference this ID
SELECT 
    FK.name AS ForeignKeyName,
    OBJECT_NAME(FK.parent_object_id) AS ChildTable,
    COL_NAME(fkc.child_object_id, fkc.child_column_id) AS ChildColumn,
    OBJECT_NAME(FK.referenced_object_id) AS ParentTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ParentColumn
FROM 
    sys.foreign_keys FK
INNER JOIN 
    sys_foreign_key_columns fkc ON FK.object_id = fkc.constraint_object_id
WHERE 
    FK.referenced_object_id = OBJECT_ID('dbo.customer')
ORDER BY 
    ChildTable;

-- List all user-defined tables and their primary keys for a quick overview of the schema structure
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    pk.type_name AS KeyType
FROM 
    sys.tables t
JOIN 
    sys.indexes i ON t.object_id = i.object_id
JOIN 
    sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN 
    sys.columns c ON t.object_id = c.object_id AND ic.column_id = c.column_id
LEFT JOIN 
    sys.key_constraints ksc ON t.object_id = ksc.parent_object_id AND i.index_id = ksc.unique_index_id
LEFT JOIN 
    sys.types ty ON c.system_type_id = ty.user_type_id
WHERE 
    t.schema_id = SCHEMA_ID('dbo')
ORDER BY 
    TableName, ColumnName;
