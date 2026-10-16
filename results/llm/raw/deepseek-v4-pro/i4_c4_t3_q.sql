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
    t.name AS table_name,
    i.type_desc,
    i.is_unique,
    i.has_filter,
    i.filter_definition
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.name IN ('customer', 'member');

SELECT 
    t.name AS table_name,
    p.rows AS row_count
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE t.name IN ('customer', 'member') AND p.index_id IN (0, 1);

SELECT 
    t.name AS table_name,
    c.name AS column_name,
    ic.key_ordinal,
    i.name AS index_name,
    i.type_desc
FROM sys.index_columns ic
JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.name IN ('customer', 'member')
ORDER BY t.name, i.name, ic.key_ordinal;
