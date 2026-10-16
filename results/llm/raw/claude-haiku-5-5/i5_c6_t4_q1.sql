-- QUERY
SELECT COUNT(*) AS remaining_rows
FROM dbo.customer
WHERE customer_id = 42
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
   OR full_name = N'Subject_0000042';
