SET NOCOUNT ON;

DECLARE @CustomerId INT = 42;
DECLARE @FullName NVARCHAR(255) = N'Subject_0000042';
DECLARE @Email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @Phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #Results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check current table
INSERT INTO #Results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

-- Check history table
INSERT INTO #Results (object_name, rows_found)
SELECT 
    N'dbo.customer_history',
    COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

-- Return results
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
