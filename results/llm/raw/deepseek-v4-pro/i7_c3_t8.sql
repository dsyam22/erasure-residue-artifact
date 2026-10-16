DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

SELECT
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = @customer_id
  AND full_name = @full_name
  AND email = @email
  AND phone = @phone

UNION ALL

SELECT
    'reporting.customer_replica' AS object_name,
    COUNT(*) AS rows_found
FROM reporting.customer_replica
WHERE customer_id = @customer_id
  AND full_name = @full_name
  AND email = @email
  AND phone = @phone;
