SET NOCOUNT ON;

CREATE TABLE #erasure_check (
    object_name nvarchar(260) NOT NULL,
    rows_found  bigint        NOT NULL
);

INSERT INTO #erasure_check (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email     = N'subject42@example.invalid'
   OR phone     = N'+1-555-0000042';

INSERT INTO #erasure_check (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email     = N'subject42@example.invalid'
   OR phone     = N'+1-555-0000042';

SELECT object_name, rows_found
FROM #erasure_check
ORDER BY object_name;

DROP TABLE #erasure_check;
