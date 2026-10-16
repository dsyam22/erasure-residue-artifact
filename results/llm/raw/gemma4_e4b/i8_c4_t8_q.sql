SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    CASE WHEN c.is_nullable = 1 THEN 'Yes' ELSE 'No' END AS IsNullable
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    TableName, ColumnName;

-- Additionally check for materialized views or indexed views that might store related data
SELECT 
    s.name AS SchemaName, 
    v.name AS ViewName, 
    OBJECT_DEFINITION(v.object_id) AS DefinitionSnippet
FROM 
    sys.views v
JOIN 
    sys.schemas s ON v.schema_id = s.schema_id
WHERE 
    s.name = 'dbo' 
ORDER BY 
    ViewName;

-- Check for foreign key constraints to see if relationships exist between tables, even if the parent table row was deleted
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS ParentTable, 
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ParentColumn, 
    OBJECT_NAME(fk.referenced_object_id) AS ChildTable, 
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ChildColumn
FROM 
    sys.foreign_keys fk
INNER JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE 
    OBJECTPROPERTY(fk.parent_object_id, 'IsUserTable') = 1 -- Only user-defined foreign keys
ORDER BY 
    ParentTable;
