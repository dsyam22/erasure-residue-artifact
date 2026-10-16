-- SCRIPT
DECLARE @phone_to_find NVARCHAR(50) = '+1-555-0000042';

SELECT 
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
  AND phone = @phone_to_find;
