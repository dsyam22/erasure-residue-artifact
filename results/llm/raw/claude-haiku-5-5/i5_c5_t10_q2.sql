-- QUERY
SELECT c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS type_name,
       c.max_length,
       c.is_nullable,
       OBJECT_SCHEMA_NAME(c.object_id) AS schema_name,
       OBJECT_NAME(c.object_id) AS table_name
FROM sys.columns AS c
WHERE c.object_id IN (OBJECT_ID(N'dbo.customer'), OBJECT_ID(N'dbo.customer_history'))
ORDER BY table_name, c.column_id;
