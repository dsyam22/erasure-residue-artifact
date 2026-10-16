-- QUERY
SELECT 
    OBJECT_SCHEMA_NAME(object_id) AS schema_name,
    name AS table_name,
    (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id = t.object_id) AS column_count
FROM sys.tables t
WHERE OBJECT_SCHEMA_NAME(object_id) = 'dbo'
ORDER BY name;
