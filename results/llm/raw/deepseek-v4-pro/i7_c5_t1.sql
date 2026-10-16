-- SCRIPT
DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(100) = 'Subject_0000042';
DECLARE @email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @phone NVARCHAR(50) = '+1-555-0000042';

SELECT 
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone

UNION ALL

SELECT 
    'reporting.customer_replica' AS object_name,
    COUNT(*) AS rows_found
FROM reporting.customer_replica
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;
