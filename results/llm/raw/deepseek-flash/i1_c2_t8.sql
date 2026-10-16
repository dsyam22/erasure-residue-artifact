SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @fn nvarchar(200) = N'Subject_0000042';
DECLARE @em nvarchar(200) = N'subject42@example.invalid';
DECLARE @ph nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #r (object_name sysname, rows_found bigint);

INSERT INTO #r (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @fn
   OR email = @em
   OR phone = @ph;

INSERT INTO #r (object_name, rows_found)
SELECT 'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @cid
   OR full_name = @fn
   OR email = @em
   OR phone = @ph;

SELECT object_name, rows_found
FROM #r;

DROP TABLE #r;
