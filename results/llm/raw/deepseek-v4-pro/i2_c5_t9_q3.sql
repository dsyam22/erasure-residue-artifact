-- QUERY
SELECT 
    t.name AS table_name,
    SUM(CASE WHEN c.name = 'customer_id' THEN 1 ELSE 0 END) AS has_customer_id,
    SUM(CASE WHEN c.name = 'full_name' THEN 1 ELSE 0 END) AS has_full_name,
    SUM(CASE WHEN c.name = 'email' THEN 1 ELSE 0 END) AS has_email,
    SUM(CASE WHEN c.name = 'phone' THEN 1 ELSE 0 END) AS has_phone
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.name IN ('customer', 'customer_history')
GROUP BY t.name;
