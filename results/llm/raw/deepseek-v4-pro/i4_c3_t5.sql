DECLARE @subject_customer_id INT = 42;
DECLARE @subject_full_name NVARCHAR(255) = 'Subject_0000042';
DECLARE @subject_email NVARCHAR(255) = 'subject42@example.invalid';
DECLARE @subject_phone NVARCHAR(255) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255) NOT NULL,
    rows_found INT NOT NULL
);

-- Check current dbo.customer table
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @subject_customer_id
  AND (full_name = @subject_full_name OR email = @subject_email OR phone = @subject_phone);

-- Check current dbo.member table (system-versioned temporal table current rows)
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @subject_customer_id
  AND (full_name = @subject_full_name OR email = @subject_email OR phone = @subject_phone);

-- Check dbo.member_history table (temporal history rows)
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member_history', COUNT(*)
FROM dbo.member_history
WHERE member_id = @subject_customer_id
  AND (full_name = @subject_full_name OR email = @subject_email OR phone = @subject_phone);

-- Check CDC change table for dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @subject_customer_id
  AND (full_name = @subject_full_name OR email = @subject_email OR phone = @subject_phone);

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
