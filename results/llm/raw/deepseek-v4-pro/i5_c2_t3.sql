SET NOCOUNT ON;

DECLARE @CustomerId INT = 42;
DECLARE @FullName NVARCHAR(100) = N'Subject_0000042';
DECLARE @Email NVARCHAR(100) = N'subject42@example.invalid';
DECLARE @Phone NVARCHAR(50) = N'+1-555-0000042';

CREATE TABLE #Results (
    object_name NVARCHAR(255) NOT NULL,
    rows_found INT NOT NULL
);

INSERT INTO #Results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

INSERT INTO #Results (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

SELECT object_name, rows_found
FROM #Results;

DROP TABLE #Results;
