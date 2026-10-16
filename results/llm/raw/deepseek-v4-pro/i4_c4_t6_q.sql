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
    fk.name AS fk_name,
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS referencing_column,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS referenced_column
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) IN ('customer', 'member')
   OR OBJECT_NAME(fk.referenced_object_id) IN ('customer', 'member');

SELECT 
    i.name AS index_name,
    OBJECT_NAME(i.object_id) AS table_name,
    i.type_desc,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS index_columns
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE OBJECT_NAME(i.object_id) IN ('customer', 'member')
GROUP BY i.name, i.object_id, i.type_desc;
