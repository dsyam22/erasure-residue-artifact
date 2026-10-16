SELECT 'dbo.customer' AS object_name, COUNT(T1.customer_id) AS rows_found FROM dbo.customer AS T1 WHERE T1.customer_id = 42 AND T1.full_name = N'Subject_0000042' AND T1.email = N'subject42@example.invalid' AND T1.phone = N'+1-555-0000042'
UNION ALL
SELECT 'reporting.customer_replica', COUNT(T2.customer_id) FROM reporting.customer_replica AS T2 WHERE T2.customer_id = 42 AND T2.full_name = N'Subject_0000042' AND T2.email = N'subject42@example.invalid' AND T2.phone = N'+1-555-0000042';
