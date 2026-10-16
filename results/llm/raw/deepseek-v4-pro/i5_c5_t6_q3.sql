-- QUERY
SELECT 
    t.name AS table_name,
    SUM(CASE WHEN c.name = 'customer_id' AND c.value = 42 THEN 1 ELSE 0 END) AS has_customer_id_42,
    SUM(CASE WHEN c.name = 'full_name' AND c.value = N'Subject_0000042' THEN 1 ELSE 0 END) AS has_full_name,
    SUM(CASE WHEN c.name = 'email' AND c.value = N'subject42@example.invalid' THEN 1 ELSE 0 END) AS has_email,
    SUM(CASE WHEN c.name = 'phone' AND c.value = N'+1-555-0000042' THEN 1 ELSE 0 END) AS has_phone
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
CROSS APPLY (SELECT value FROM (VALUES 
    (SELECT customer_id FROM dbo.customer WHERE customer_id = 42),
    (SELECT customer_id FROM dbo.customer_history WHERE customer_id = 42)
) v(value)) x
WHERE t.name IN ('customer', 'customer_history')
GROUP BY t.name;
