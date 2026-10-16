SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type_name,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE SCHEMA_NAME(t.schema_id) IN ('dbo')
ORDER BY t.name, c.column_id;

SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    i.filter_definition
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
WHERE SCHEMA_NAME(t.schema_id) IN ('dbo')
ORDER BY t.name, i.index_id;

SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE SCHEMA_NAME(t.schema_id) IN ('dbo')
GROUP BY SCHEMA_NAME(t.schema_id), t.name
ORDER BY t.name;
