SELECT 'dbo.customer' AS object_name, COUNT(*) AS rows_found 
FROM dbo.customer 
WHERE customer_id = 42

UNION ALL

SELECT 'dbo.member' AS object_name, COUNT(*) AS rows_found 
FROM dbo.member 
WHERE member_id = 42

UNION ALL

SELECT 'dbo.member_history' AS object_name, COUNT(*) AS rows_found 
FROM dbo.member_history 
WHERE member_id = 42

UNION ALL

SELECT 'cdc.dbo_customer_CT' AS object_name, COUNT(*) AS rows_found 
FROM cdc.dbo_customer_CT 
WHERE customer_id = 42;
