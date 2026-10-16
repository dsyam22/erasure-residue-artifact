-- QUERY
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc
FROM sys.indexes AS i
WHERE OBJECT_NAME(i.object_id) IN ('customer', 'customer_history')
ORDER BY table_name, i.index_id;
