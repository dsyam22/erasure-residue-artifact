-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name IN ('customer', 'customer_history')
ORDER BY t.name, c.column_id;
