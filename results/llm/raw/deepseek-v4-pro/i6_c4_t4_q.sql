SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
WHERE 
    c.name LIKE '%phone%'
    OR c.name LIKE '%tel%'
    OR c.name LIKE '%mobile%'
    OR c.name LIKE '%contact%'
ORDER BY 
    schema_name, table_name, column_name;
