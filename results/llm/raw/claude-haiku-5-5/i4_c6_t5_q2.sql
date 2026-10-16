-- QUERY
SELECT 'dbo.customer' AS object_name,
       COUNT(*) AS matching_rows
FROM dbo.customer
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
   OR customer_id = 42
UNION ALL
SELECT 'dbo.member',
       COUNT(*)
FROM dbo.member
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
   OR member_id = 42
UNION ALL
SELECT 'dbo.member_history',
       COUNT(*)
FROM dbo.member_history
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
   OR member_id = 42;
