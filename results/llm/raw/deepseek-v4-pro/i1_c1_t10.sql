DECLARE @CustomerId INT = 42;
DECLARE @FullName NVARCHAR(255) = N'Subject_0000042';
DECLARE @Email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @Phone NVARCHAR(255) = N'+1-555-0000042';

SELECT
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;
