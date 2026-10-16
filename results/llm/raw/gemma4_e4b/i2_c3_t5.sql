SELECT 'dbo.customer' AS object_name, COUNT(T1.customer_id) AS rows_found FROM dbo.customer T1 WHERE T1.customer_id = 42
UNION ALL
SELECT 'dbo.customer_history', COUNT(T2.customer_id) FROM dbo.customer_history T2 WHERE T2.customer_id = 42;
