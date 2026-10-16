DECLARE @cid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

INSERT INTO #results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT', COUNT_BIG(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM #results;

DROP TABLE #results;
