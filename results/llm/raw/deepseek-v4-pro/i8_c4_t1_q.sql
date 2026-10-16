SELECT 
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'customer'
ORDER BY c.column_id;

SELECT 
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    i.is_disabled,
    i.filter_definition
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.name = 'customer';

SELECT 
    p.partition_number,
    p.rows,
    au.total_pages,
    au.used_pages,
    au.data_pages
FROM sys.partitions p
JOIN sys.allocation_units au ON p.partition_id = au.container_id
WHERE p.object_id = OBJECT_ID('dbo.customer');

SELECT 
    fk.name AS foreign_key_name,
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS referencing_column,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS referenced_column
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.referenced_object_id = OBJECT_ID('dbo.customer')
   OR fk.parent_object_id = OBJECT_ID('dbo.customer');
