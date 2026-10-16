SET NOCOUNT ON;

CREATE TABLE #check_results (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

-- dbo.customer: live table (rows for the subject were deleted, so expect 0)
INSERT INTO #check_results (object_name, rows_found)
SELECT 'dbo.customer',
       COUNT(*)
FROM dbo.customer AS c
WHERE c.customer_id = 42
   OR c.full_name = N'Subject_0000042'
   OR c.email = N'subject42@example.invalid'
   OR c.phone = N'+1-555-0000042';

-- cdc.dbo_customer_CT: CDC change table, which retains captured column values of changed rows
INSERT INTO #check_results (object_name, rows_found)
SELECT 'cdc.dbo_customer_CT',
       COUNT(*)
FROM cdc.dbo_customer_CT AS ct
WHERE ct.customer_id = 42
   OR ct.full_name = N'Subject_0000042'
   OR ct.email = N'subject42@example.invalid'
   OR ct.phone = N'+1-555-0000042';

SELECT object_name, rows_found
FROM #check_results
ORDER BY object_name;

DROP TABLE #check_results;
