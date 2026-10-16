DECLARE @CustomerID INT = 42;
DECLARE @FullName NVARCHAR(100) = 'Subject_0000042';
DECLARE @Email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @Phone NVARCHAR(50) = '+1-555-0000042';

-- Use a temporary table to collect the results structure (object_name, rows_found)
IF OBJECT_ID('tempdb..#VerificationResults') IS NOT NULL DROP TABLE #VerificationResults;

CREATE TABLE #VerificationResults (
    object_name NVARCHAR(128),
    rows_found INT
);

-- 1. Check the primary table: dbo.customer
INSERT INTO #VerificationResults (object_name, rows_found)
SELECT
    N'dbo.customer',
    COUNT(*)
FROM
    dbo.customer
WHERE
    customer_id = @CustomerID
AND full_name = @FullName
AND email = @Email
AND phone = @Phone;

-- 2. Check the CDC history table: cdc.dbo_customer_CT
INSERT INTO #VerificationResults (object_name, rows_found)
SELECT
    N'cdc.dbo_customer_CT',
    COUNT(*)
FROM
    cdc.dbo_customer_CT
WHERE
    -- Assuming all original columns are present in the CT table
    customer_id = @CustomerID
AND full_name = @FullName
AND email = @Email
AND phone = @Phone;

-- Return the final result set exactly as required
SELECT
    object_name,
    rows_found
FROM
    #VerificationResults
ORDER BY
    CASE WHEN object_name LIKE 'dbo.customer' THEN 0 ELSE 1 END; -- Ensure deterministic order

DROP TABLE #VerificationResults;
