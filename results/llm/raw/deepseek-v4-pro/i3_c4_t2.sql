SELECT 'dbo.customer' AS object_name, COUNT(*) AS rows_found
FROM dbo.customer
WHERE (customer_id = 42)
   OR (full_name = N'Subject_0000042' AND email = N'subject42@example.invalid')
   OR (full_name = N'Subject_0000042' AND phone = N'+1-555-0000042')
   OR (email = N'subject42@example.invalid' AND phone = N'+1-555-0000042')
UNION ALL
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE (member_id = 42)
   OR (full_name = N'Subject_0000042' AND email = N'subject42@example.invalid')
   OR (full_name = N'Subject_0000042' AND phone = N'+1-555-0000042')
   OR (email = N'subject42@example.invalid' AND phone = N'+1-555-0000042');
