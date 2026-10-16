SET NOCOUNT ON;

CREATE TABLE #results (
    object_name nvarchar(257),
    rows_found int
);

-- Check dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- Check dbo.member (current rows in system-versioned table)
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.member',
    COUNT(*)
FROM dbo.member
WHERE member_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- Check dbo.member_history
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.member_history',
    COUNT(*)
FROM dbo.member_history
WHERE member_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- Check cdc.dbo_customer_CT
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'cdc.dbo_customer_CT',
    COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
