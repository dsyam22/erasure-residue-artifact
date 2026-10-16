SELECT 
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('customer', 'member')
ORDER BY t.name, c.column_id;

SELECT 
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) IN ('customer', 'member')
ORDER BY table_name, i.index_id;

SELECT 
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS referencing_column,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS referenced_column
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) IN ('customer', 'member')
   OR OBJECT_NAME(fk.referenced_object_id) IN ('customer', 'member');

SELECT 
    tr.name AS trigger_name,
    OBJECT_NAME(tr.parent_id) AS table_name,
    tr.is_disabled,
    tr.type_desc
FROM sys.triggers tr
WHERE OBJECT_NAME(tr.parent_id) IN ('customer', 'member');

SELECT 
    dc.name AS default_constraint_name,
    OBJECT_NAME(dc.parent_object_id) AS table_name,
    COL_NAME(dc.parent_object_id, dc.parent_column_id) AS column_name,
    dc.definition
FROM sys.default_constraints dc
WHERE OBJECT_NAME(dc.parent_object_id) IN ('customer', 'member');

SELECT 
    cc.name AS check_constraint_name,
    OBJECT_NAME(cc.parent_object_id) AS table_name,
    cc.definition
FROM sys.check_constraints cc
WHERE OBJECT_NAME(cc.parent_object_id) IN ('customer', 'member');
