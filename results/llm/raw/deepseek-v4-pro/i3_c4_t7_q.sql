SELECT 
    SCHEMA_NAME(o.schema_id) AS schema_name,
    o.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable,
    o.type_desc AS object_type
FROM sys.objects o
JOIN sys.columns c ON o.object_id = c.object_id
WHERE o.is_ms_shipped = 0
ORDER BY schema_name, table_name, c.column_id;
