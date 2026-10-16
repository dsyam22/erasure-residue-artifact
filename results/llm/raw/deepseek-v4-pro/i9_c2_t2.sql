SET NOCOUNT ON;

-- Temporary table to store results
CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found BIGINT
);

-- Check dbo.customer (current table)
INSERT INTO #results (object_name, rows_found)
SELECT 
    'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE 
    customer_id = 42
    OR full_name = 'Subject_0000042'
    OR email = 'subject42@example.invalid'
    OR phone = '+1-555-0000042';

-- Check dbo.customer_history (history table)
INSERT INTO #results (object_name, rows_found)
SELECT 
    'dbo.customer_history',
    COUNT(*)
FROM dbo.customer_history
WHERE 
    customer_id = 42
    OR full_name = 'Subject_0000042'
    OR email = 'subject42@example.invalid'
    OR phone = '+1-555-0000042';

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
