SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* cdc.dbo_customer_CT */
IF OBJECT_ID(N'cdc.dbo_customer_CT', N'U') IS NOT NULL
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @cid
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', 0;
END

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
