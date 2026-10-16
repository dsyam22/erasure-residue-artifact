-- SCRIPT
DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = 'Subject_0000042';
DECLARE @email NVARCHAR(255) = 'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = '+1-555-0000042';

SELECT 'dbo.customer' AS object_name,
       COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone

UNION ALL

SELECT 'dbo.customer_history' AS object_name,
       COUNT(*) AS rows_found
FROM dbo.customer_history
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;
