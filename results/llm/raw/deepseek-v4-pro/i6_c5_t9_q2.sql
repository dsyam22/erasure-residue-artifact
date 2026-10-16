-- QUERY
SELECT OBJECT_SCHEMA_NAME(object_id) AS schema_name, name AS table_name
FROM sys.tables
WHERE is_ms_shipped = 0;
