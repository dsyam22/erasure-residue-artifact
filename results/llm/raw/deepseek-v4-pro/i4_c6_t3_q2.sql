-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.name IN ('customer', 'member', 'member_history', 'dbo_customer_CT')
ORDER BY t.name, c.column_id;
