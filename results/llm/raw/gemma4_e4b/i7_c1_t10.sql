SELECT 'dbo.customer' AS object_name, COUNT(T.customer_id) AS rows_found FROM dbo.customer AS T WHERE T.customer_id = 42 GROUP BY 'dbo.customer'
UNION ALL
SELECT 'reporting.customer_replica' AS object_name, COUNT(T.customer_id) AS rows_found FROM reporting.customer_replica AS T WHERE T.customer_id = 42 GROUP BY 'reporting.customer_replica';
