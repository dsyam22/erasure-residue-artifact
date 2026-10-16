SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255) NOT NULL,
    rows_found int NOT NULL
);

-- Check dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Check dbo.member (current rows)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Check dbo.member_history (temporal history)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member_history', COUNT(*)
FROM dbo.member_history
WHERE member_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Check CDC change table for dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Ensure all objects are represented (even if not present in #results yet)
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'dbo.customer')
    INSERT INTO #results VALUES (N'dbo.customer', 0);
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'dbo.member')
    INSERT INTO #results VALUES (N'dbo.member', 0);
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'dbo.member_history')
    INSERT INTO #results VALUES (N'dbo.member_history', 0);
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'cdc.dbo_customer_CT')
    INSERT INTO #results VALUES (N'cdc.dbo_customer_CT', 0);

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
