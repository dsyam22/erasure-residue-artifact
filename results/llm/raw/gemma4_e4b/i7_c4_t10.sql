SELECT 'dbo.customer' AS object_name, COUNT(1) AS rows_found
FROM dbo.customer
WHERE customer_id = 42

UNION ALL

SELECT 'reporting.customer_replica' AS object_name, COUNT(1) AS rows_found
FROM reporting.customer_replica
WHERE customer_id = 42;
