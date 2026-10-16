-- SCRIPT
SELECT 'cdc.dbo_customer_CT' AS object_name,
       COUNT(*) AS rows_found
FROM cdc.dbo_customer_CT
WHERE phone = N'+1-555-0000042'

UNION ALL

SELECT 'dbo.customer' AS object_name,
       COUNT(*) AS rows_found
FROM dbo.customer
WHERE full_name LIKE N'%555-0000042%'
   OR email LIKE N'%555-0000042%'

UNION ALL

SELECT 'cdc.ddl_history' AS object_name,
       COUNT(*) AS rows_found
FROM cdc.ddl_history
WHERE ddl_command LIKE N'%555-0000042%';
