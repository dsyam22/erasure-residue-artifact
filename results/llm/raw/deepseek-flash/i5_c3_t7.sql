SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* Current table */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

/* Temporal history table */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history',
       COUNT_BIG(*)
FROM dbo.customer_history
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM #results;

DROP TABLE #results;
