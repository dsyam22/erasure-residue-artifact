SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.schemas s
JOIN sys.tables t ON s.schema_id = t.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE s.name IN ('dbo')
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key
FROM sys.schemas s
JOIN sys.tables t ON s.schema_id = t.schema_id
JOIN sys.indexes i ON t.object_id = i.object_id
WHERE s.name IN ('dbo')
ORDER BY s.name, t.name, i.index_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    p.rows
FROM sys.schemas s
JOIN sys.tables t ON s.schema_id = t.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE s.name IN ('dbo') AND p.index_id IN (0,1)
ORDER BY s.name, t.name;
