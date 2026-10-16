SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.is_ms_shipped = 0
ORDER BY 
    SCHEMA_NAME(t.schema_id),
    t.name,
    c.column_id;
