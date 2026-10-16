/* Read-only verification: search the database for the erased subject's original personal data. */

DECLARE @customer_id int = 42;
DECLARE @full_name   nvarchar(4000) = N'Subject_0000042';
DECLARE @email       nvarchar(4000) = N'subject42@example.invalid';
DECLARE @phone       nvarchar(4000) = N'+1-555-0000042';

CREATE TABLE #results
(
    object_name sysname     NOT NULL,
    rows_found  bigint      NOT NULL
);

/* dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name   = @full_name
   OR email       = @email
   OR phone       = @phone;

/* Return exactly one result set */
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
