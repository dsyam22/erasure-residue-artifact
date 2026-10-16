/* Read-only verification script:
   Checks whether the erased subject's original personal data (customer_id 42,
   full_name 'Subject_0000042', email 'subject42@example.invalid',
   phone '+1-555-0000042') is still stored anywhere in this database.

   Scope of objects checked:
     - dbo.customer          (current table)
     - dbo.customer_history  (system-versioned temporal history table)

   Returns exactly one result set: object_name, rows_found. */

SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name  nvarchar(200) = N'Subject_0000042';
DECLARE @email      nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone      nvarchar(50)  = N'+1-555-0000042';

CREATE TABLE #results
(
    object_name sysname     NOT NULL,
    rows_found  bigint      NOT NULL
);

/* dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name   = @full_name
   OR email       = @email
   OR phone       = @phone;

/* dbo.customer_history */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history',
       COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @customer_id
   OR full_name   = @full_name
   OR email       = @email
   OR phone       = @phone;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
