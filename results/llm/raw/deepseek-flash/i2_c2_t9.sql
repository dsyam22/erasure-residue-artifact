DECLARE @cid int = 42;
DECLARE @fn nvarchar(200) = N'Subject_0000042';
DECLARE @em nvarchar(200) = N'subject42@example.invalid';
DECLARE @ph nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #r (object_name nvarchar(256), rows_found bigint);

INSERT INTO #r
SELECT N'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @fn
   OR email = @em
   OR phone = @ph;

INSERT INTO #r
SELECT N'dbo.customer_history',
       COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @cid
   OR full_name = @fn
   OR email = @em
   OR phone = @ph;

SELECT object_name, rows_found
FROM #r;

DROP TABLE #r;
