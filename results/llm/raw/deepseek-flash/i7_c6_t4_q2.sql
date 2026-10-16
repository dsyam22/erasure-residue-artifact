-- QUERY
SELECT c.customer_id, c.full_name, c.email, c.phone
FROM dbo.customer AS c
WHERE c.customer_id = 42
   OR c.full_name = N'Subject_0000042'
   OR c.email = N'subject42@example.invalid'
   OR c.phone = N'+1-555-0000042';
