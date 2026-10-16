-- SCRIPT
SET NOCOUNT ON;

SELECT 'dbo.customer' AS object_name,
       CAST(0 AS int) AS rows_found   -- phone column was dropped; no phone value can exist here
UNION ALL
SELECT 'cdc.dbo_customer_CT' AS object_name,
       CAST(COUNT(*) AS int) AS rows_found
FROM cdc.dbo_customer_CT
WHERE phone = N'+1-555-0000042'
UNION ALL
SELECT 'cdc.ddl_history' AS object_name,
       CAST(COUNT(*) AS int) AS rows_found
FROM cdc.ddl_history
WHERE ddl_command LIKE N'%+1-555-0000042%';
