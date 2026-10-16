SELECT
    'dbo.customer' AS object_name,
    COUNT(1) AS rows_found
UNION ALL
SELECT
    'dbo.customer_history' AS object_name,
    COUNT(1)
FROM dbo.customer_history
WHERE customer_id = 42;
