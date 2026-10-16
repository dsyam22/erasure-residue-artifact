-- QUERY
SELECT OBJECT_SCHEMA_NAME(t.object_id) AS schema_name, t.name AS table_name
FROM sys.tables t
WHERE t.is_ms_shipped = 0
  AND OBJECT_SCHEMA_NAME(t.object_id) NOT IN ('dbo','cdc')
ORDER BY schema_name, table_name;
