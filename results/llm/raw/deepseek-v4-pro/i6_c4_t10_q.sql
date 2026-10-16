SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type_name,
    c.max_length,
    c.is_nullable
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE 
    c.name LIKE '%phone%'
    OR c.name LIKE '%tel%'
    OR c.name LIKE '%contact%'
    OR c.name LIKE '%mobile%'
    OR c.name LIKE '%fax%'
ORDER BY 
    schema_name, table_name, column_name;
