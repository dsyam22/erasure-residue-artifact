-- QUERY
SELECT OBJECT_SCHEMA_NAME(object_id) AS schema_name, OBJECT_NAME(object_id) AS table_name
FROM sys.tables
WHERE is_ms_shipped = 0
ORDER BY schema_name, table_name;
