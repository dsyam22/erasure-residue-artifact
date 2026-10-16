/* Read-only verification: is the erased subject's personal data still stored anywhere? */
DECLARE @cid int = 42;
DECLARE @fname nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50)  = N'+1-555-0000042';

CREATE TABLE #res (object_name sysname NOT NULL, rows_found bigint NOT NULL);

/* 1. Current table */
INSERT INTO #res (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @fname
   OR email = @email
   OR phone = @phone;

/* 2. Temporal history table */
INSERT INTO #res (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT_BIG(*)
FROM dbo.customer_history
WHERE customer_id = @cid
   OR full_name = @fname
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM #res
ORDER BY object_name;

DROP TABLE #res;
