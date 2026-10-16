-- SCRIPT
SELECT 'dbo.customer' AS object_name,
       COUNT(*) AS rows_found
FROM dbo.customer
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
UNION ALL
SELECT 'cdc.dbo_customer_CT' AS object_name,
       COUNT(*) AS rows_found
FROM cdc.dbo_customer_CT
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
UNION ALL
SELECT 'cdc.ddl_history' AS object_name,
       COUNT(*) AS rows_found
FROM cdc.ddl_history
WHERE CHARINDEX(N'Subject_0000042', ddl_command) > 0
   OR CHARINDEX(N'subject42@example.invalid', ddl_command) > 0
   OR CHARINDEX(N'+1-555-0000042', ddl_command) > 0;
