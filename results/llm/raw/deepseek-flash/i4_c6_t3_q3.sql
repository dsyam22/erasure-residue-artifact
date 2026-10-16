-- QUERY
SELECT 'dbo.customer' AS object_name, COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
  AND (full_name = N'Subject_0000042' OR email = N'subject42@example.invalid' OR phone = N'+1-555-0000042')
UNION ALL
SELECT 'dbo.member' AS object_name, COUNT(*) AS rows_found
FROM dbo.member
WHERE member_id = 42
  AND (full_name = N'Subject_0000042' OR email = N'subject42@example.invalid' OR phone = N'+1-555-0000042');
