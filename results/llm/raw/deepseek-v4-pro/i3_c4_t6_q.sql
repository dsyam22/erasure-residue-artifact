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
    i.name AS index_name,
    i.type_desc AS index_type,
    i.is_unique,
    i.is_primary_key,
    i.is_disabled,
    OBJECT_NAME(i.object_id) AS table_name
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) IN ('customer', 'member')
ORDER BY table_name, i.index_id;

SELECT 
    fk.name AS foreign_key_name,
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    fk.is_disabled
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.parent_object_id) IN ('customer', 'member')
   OR OBJECT_NAME(fk.referenced_object_id) IN ('customer', 'member');

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.name IN ('customer', 'member')
ORDER BY o.type_desc, o.name;
