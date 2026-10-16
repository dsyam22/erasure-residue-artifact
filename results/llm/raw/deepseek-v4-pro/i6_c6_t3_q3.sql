-- QUERY
SELECT OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id) AS object_name
FROM sys.columns
WHERE name = 'phone';
