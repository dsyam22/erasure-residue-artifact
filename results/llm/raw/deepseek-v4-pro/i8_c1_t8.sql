SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #Results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer
INSERT INTO #Results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE 
    customer_id = @customer_id
    OR full_name = @full_name
    OR email = @email
    OR phone = @phone;

-- Return final result set
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
