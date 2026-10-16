-- QUERY
SELECT 
    OBJECT_SCHEMA_NAME(object_id) AS schema_name,
    OBJECT_NAME(object_id) AS table_name,
    name AS column_name
FROM sys.columns
WHERE OBJECT_SCHEMA_NAME(object_id) IN ('dbo', 'reporting')
  AND OBJECT_NAME(object_id) IN ('customer', 'customer_replica');
