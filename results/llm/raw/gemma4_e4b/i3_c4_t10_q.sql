SELECT 
    t.name AS TableName, 
    c.name AS ColumnName, 
    ty.name AS DataType,
    c.max_length AS MaxLength,
    ISNULL(c.is_nullable, 1) AS IsNullable
FROM 
    sys.tables t
JOIN 
    sys.columns c ON t.object_id = c.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_id = SCHEMA_ID('dbo')
ORDER BY 
    TableName, c.column_id;

SELECT
    tc.CONSTRAINT_NAME,
    OBJECT_NAME(tc.parent_object_id) AS TableName,
    COL_NAME(tc.parent_object_id, tc.parent_column_id) AS ParentColumn,
    OBJECT_NAME(tc.referenced_object_id) AS ReferencedTable,
    COL_NAME(tc.referenced_object_id, tc.referenced_column_id) AS ReferencedColumn
FROM 
    sys.foreign_keys AS fk
JOIN 
    sys_schema.columns AS col ON fk.parent_object_id = OBJECT_ID(col.table_name + '.' + col.column_name) AND fk.parent_column_id = col.column_id
JOIN 
    sys_foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
JOIN
    sys.tables AS t ON OBJECT_ID(t.name + '.' + 'dbo') = fk.parent_object_id -- Assuming standard dbo schema
WHERE 
    OBJECT_NAME(fk.parent_object_id) IN ('customer', 'member') OR OBJECT_NAME(fk.referenced_object_id) IN ('customer', 'member');
