-- QUERY
SELECT COUNT(*) AS count_dbo FROM dbo.customer WHERE customer_id = 42;
SELECT COUNT(*) AS count_replica FROM reporting.customer_replica WHERE customer_id = 42;
