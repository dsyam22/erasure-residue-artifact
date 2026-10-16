-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name IN ('customer', 'customer_history')
  AND c.name IN ('customer_id', 'full_name', 'email', 'phone')
ORDER BY t.name, c.column_id;
