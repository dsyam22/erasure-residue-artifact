SELECT 'dbo.customer' AS object_name, COUNT(*) AS rows_found 
FROM dbo.customer 
WHERE customer_id = 42 OR full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042'
UNION ALL
SELECT 'dbo.member' AS object_name, COUNT(*) AS rows_found 
FROM dbo.member 
WHERE member_id = 42 OR full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042'
UNION ALL
SELECT 'dbo.member_history' AS object_name, COUNT(*) AS rows_found 
FROM dbo.member_history 
WHERE member_id = 42 OR full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042';
