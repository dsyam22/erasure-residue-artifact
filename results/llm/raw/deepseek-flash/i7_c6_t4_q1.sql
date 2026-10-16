-- QUERY
SELECT name AS object_name, schema_name = SCHEMA_NAME(schema_id), type_desc
FROM sys.objects
WHERE name IN ('customer', 'customer_replica')
ORDER BY schema_name, name;
