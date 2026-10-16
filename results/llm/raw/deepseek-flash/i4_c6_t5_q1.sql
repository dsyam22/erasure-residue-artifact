-- QUERY
SELECT name, object_id, schema_id
FROM sys.tables
WHERE name IN ('customer', 'member');
