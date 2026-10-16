SELECT 'dbo.customer' AS object_name, COUNT(1) AS rows_found FROM dbo.customer WHERE full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042'
UNION ALL
SELECT 'dbo.member', COUNT(1) FROM dbo.member WHERE full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042';
