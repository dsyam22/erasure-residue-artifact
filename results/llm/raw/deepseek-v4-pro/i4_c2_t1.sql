DECLARE @OriginalFullName nvarchar(255) = 'Subject_0000042';
DECLARE @OriginalEmail nvarchar(255) = 'subject42@example.invalid';
DECLARE @OriginalPhone nvarchar(255) = '+1-555-0000042';

CREATE TABLE #Results (
    object_name nvarchar(255),
    rows_found int
);

-- Check dbo.customer
INSERT INTO #Results (object_name, rows_found)
SELECT 
    'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
  AND (full_name = @OriginalFullName
       OR email = @OriginalEmail
       OR phone = @OriginalPhone);

-- Check dbo.member
INSERT INTO #Results (object_name, rows_found)
SELECT 
    'dbo.member',
    COUNT(*)
FROM dbo.member
WHERE member_id = 42
  AND (full_name = @OriginalFullName
       OR email = @OriginalEmail
       OR phone = @OriginalPhone);

-- Check dbo.member_history
INSERT INTO #Results (object_name, rows_found)
SELECT 
    'dbo.member_history',
    COUNT(*)
FROM dbo.member_history
WHERE member_id = 42
  AND (full_name = @OriginalFullName
       OR email = @OriginalEmail
       OR phone = @OriginalPhone);

-- Check CDC capture instance cdc.dbo_customer_CT
INSERT INTO #Results (object_name, rows_found)
SELECT 
    'cdc.dbo_customer_CT',
    COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = 42
  AND (full_name = @OriginalFullName
       OR email = @OriginalEmail
       OR phone = @OriginalPhone);

-- Return final result set
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
