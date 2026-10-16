-- SCRIPT
SELECT 'cdc.dbo_customer_CT' AS object_name,
       COUNT(*) AS rows_found
FROM cdc.dbo_customer_CT
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
UNION ALL
SELECT 'cdc.ddl_history',
       COUNT(*)
FROM cdc.ddl_history
WHERE CHARINDEX(N'Subject_0000042', ddl_command) > 0
   OR CHARINDEX(N'subject42@example.invalid', ddl_command) > 0
   OR CHARINDEX(N'+1-555-0000042', ddl_command) > 0
UNION ALL
SELECT 'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
UNION ALL
SELECT 'dbo.member',
       COUNT(*)
FROM dbo.member
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
UNION ALL
SELECT 'dbo.member_history',
       COUNT(*)
FROM dbo.member_history
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
ORDER BY object_name;
