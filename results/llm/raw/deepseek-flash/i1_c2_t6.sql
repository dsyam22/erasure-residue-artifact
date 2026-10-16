/* Read-only verification of residual personal data after erasure.
   Returns one result set: object_name, rows_found. */

DECLARE @cid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* 1. Base table dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

/* 2. CDC change table cdc.dbo_customer_CT (captured columns only) */
INSERT INTO #results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT',
       COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM #results;

DROP TABLE #results;
