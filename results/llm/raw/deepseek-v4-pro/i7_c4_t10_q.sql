SELECT 
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('customer', 'customer_replica')
ORDER BY t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.indexes i ON t.object_id = i.object_id
WHERE t.name IN ('customer', 'customer_replica')
ORDER BY s.name, t.name, i.index_id;

SELECT 
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    fk.name AS foreign_key_name
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.parent_object_id) IN ('customer', 'customer_replica')
   OR OBJECT_NAME(fk.referenced_object_id) IN ('customer', 'customer_replica');

SELECT 
    t.name AS table_name,
    p.rows AS row_count
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.name IN ('customer', 'customer_replica')
ORDER BY t.name;
