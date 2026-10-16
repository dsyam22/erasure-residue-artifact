DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = 'Subject_0000042';
DECLARE @email NVARCHAR(255) = 'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 
    'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Check dbo.member
INSERT INTO #results (object_name, rows_found)
SELECT 
    'dbo.member',
    COUNT(*)
FROM dbo.member
WHERE member_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Check dbo.member_history (temporal history table)
INSERT INTO #results (object_name, rows_found)
SELECT 
    'dbo.member_history',
    COUNT(*)
FROM dbo.member_history
WHERE member_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Check CDC change table for dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 
    'cdc.dbo_customer_CT',
    COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Return final results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
