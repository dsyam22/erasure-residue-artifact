SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found bigint
);

-- 1. dbo.customer (live table)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- 2. dbo.member (live temporal table)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- 3. dbo.member_history (history table)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member_history', COUNT(*)
FROM dbo.member_history
WHERE member_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- 4. cdc.dbo_customer_CT (CDC change table for dbo.customer)
INSERT INTO #results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Output results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
