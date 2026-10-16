SET NOCOUNT ON;

DECLARE @results TABLE (
    object_name sysname NOT NULL,
    rows_found  int     NOT NULL
);

-- Current table: any row for the subject (by id or by any original personal value)
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email     = N'subject42@example.invalid'
   OR phone     = N'+1-555-0000042';

-- Temporal history table: retains prior row versions, so it must be checked too
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer_history',
       COUNT(*)
FROM dbo.customer_history
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email     = N'subject42@example.invalid'
   OR phone     = N'+1-555-0000042';

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
