-- QUERY
SELECT OBJECT_SCHEMA_NAME(object_id) AS schema_name, name AS table_name
FROM sys.tables
WHERE OBJECT_SCHEMA_NAME(object_id) = 'dbo'
ORDER BY name;
