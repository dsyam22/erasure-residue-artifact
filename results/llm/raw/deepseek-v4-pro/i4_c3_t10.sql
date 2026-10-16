DECLARE @original_full_name nvarchar(255) = 'Subject_0000042';
DECLARE @original_email nvarchar(255) = 'subject42@example.invalid';
DECLARE @original_phone nvarchar(255) = '+1-555-0000042';
DECLARE @customer_id int = 42;
DECLARE @member_id int = 42;

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found int
);

-- Check current customer table
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND (full_name = @original_full_name OR email = @original_email OR phone = @original_phone);

-- Check current member table
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @member_id
  AND (full_name = @original_full_name OR email = @original_email OR phone = @original_phone);

-- Check member history table
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member_history', COUNT(*)
FROM dbo.member_history
WHERE member_id = @member_id
  AND (full_name = @original_full_name OR email = @original_email OR phone = @original_phone);

-- Check CDC change table for customer
INSERT INTO #results (object_name, rows_found)
SELECT 'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
  AND (full_name = @original_full_name OR email = @original_email OR phone = @original_phone);

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
