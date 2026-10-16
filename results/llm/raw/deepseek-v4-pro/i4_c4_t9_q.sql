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
    i.type_desc AS index_type,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS index_columns
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.name IN ('customer', 'member')
GROUP BY i.name, t.name, i.type_desc;

SELECT 
    t.name AS table_name,
    p.partition_number,
    p.rows AS row_count
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE t.name IN ('customer', 'member')
  AND p.index_id IN (0, 1);

SELECT 
    OBJECT_NAME(m.object_id) AS table_name,
    m.definition
FROM sys.sql_modules m
WHERE OBJECT_NAME(m.object_id) IN ('customer', 'member');

SELECT 
    dc.name AS constraint_name,
    t.name AS table_name,
    c.name AS column_name,
    dc.definition
FROM sys.default_constraints dc
JOIN sys.tables t ON dc.parent_object_id = t.object_id
JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE t.name IN ('customer', 'member');

SELECT 
    cc.name AS constraint_name,
    t.name AS table_name,
    c.name AS column_name,
    cc.definition
FROM sys.check_constraints cc
JOIN sys.tables t ON cc.parent_object_id = t.object_id
JOIN sys.columns c ON cc.parent_object_id = c.object_id AND cc.parent_column_id = c.column_id
WHERE t.name IN ('customer', 'member');
