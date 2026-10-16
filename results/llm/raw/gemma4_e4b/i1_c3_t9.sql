DECLARE @CustomerID INT = 42;
DECLARE @FullName NVARCHAR(100) = 'Subject_0000042';
DECLARE @Email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @Phone NVARCHAR(50) = '+1-555-0000042';

-- Variables to store the counts
DECLARE @CustomerCount INT;
DECLARE @CdcCount INT;

-- 1. Check dbo.customer (Primary table)
SELECT @CustomerCount = COUNT(1)
FROM dbo.customer
WHERE customer_id = @CustomerID
  AND full_name = @FullName
  AND email = @Email
  AND phone = @Phone;

-- 2. Check cdc.dbo_customer_CT (Change Tracking Table)
-- Note: We assume the captured columns are accessible directly in the CT table structure.
SELECT @CdcCount = COUNT(1)
FROM cdc.dbo_customer_CT
WHERE customer_id = @CustomerID
  AND full_name = @FullName
  AND email = @Email
  AND phone = @Phone;

-- Return the required single result set
SELECT
    'dbo.customer' AS object_name,
    @CustomerCount AS rows_found
UNION ALL
SELECT
    'cdc.dbo_customer_CT' AS object_name,
    @CdcCount AS rows_found;
