-- SCRIPT
SELECT 'dbo.customer' AS object_name, 0 AS rows_found

UNION ALL

SELECT 'cdc.dbo_customer_CT' AS object_name, COUNT(*) AS rows_found
FROM cdc.dbo_customer_CT
WHERE phone = '+1-555-0000042';
