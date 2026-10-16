SELECT 'dbo.customer' AS object_name, COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid'
   OR phone = '+1-555-0000042'
UNION ALL
SELECT 'dbo.customer_history' AS object_name, COUNT(*) AS rows_found
FROM dbo.customer_history
WHERE customer_id = 42
   OR full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid'
   OR phone = '+1-555-0000042';
