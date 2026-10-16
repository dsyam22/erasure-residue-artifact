-- QUERY
SELECT t.name AS table_name,
       c.column_id,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.tables AS t
JOIN sys.columns AS c ON c.object_id = t.object_id
WHERE t.name IN ('customer', 'customer_history')
ORDER BY t.name, c.column_id;
