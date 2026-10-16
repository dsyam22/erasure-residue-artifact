SET NOCOUNT ON;

DECLARE @CustomerId INT = 42;
DECLARE @FullName NVARCHAR(255) = N'Subject_0000042';
DECLARE @Email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @Phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #Results (
    object_name NVARCHAR(255) NOT NULL,
    rows_found INT NOT NULL
);

-- Check dbo.customer
INSERT INTO #Results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

-- Return final result set
SELECT object_name, rows_found
FROM #Results;

DROP TABLE #Results;
