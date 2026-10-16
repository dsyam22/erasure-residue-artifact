SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @name nvarchar(100) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #res (object_name sysname, rows_found bigint);

-- dbo.customer
INSERT INTO #res
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
  AND (full_name = @name OR email = @email OR phone = @phone);

-- dbo.member
INSERT INTO #res
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @cid
  AND (full_name = @name OR email = @email OR phone = @phone);

-- dbo.member_history
INSERT INTO #res
SELECT 'dbo.member_history', COUNT(*)
FROM dbo.member_history
WHERE member_id = @cid
  AND (full_name = @name OR email = @email OR phone = @phone);

-- CDC change table dbo_customer_CT
IF OBJECT_ID(N'cdc.dbo_customer_CT') IS NOT NULL
BEGIN
    INSERT INTO #res
    SELECT 'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @cid
      AND (full_name = @name OR email = @email OR phone = @phone);
END
ELSE
BEGIN
    INSERT INTO #res SELECT 'cdc.dbo_customer_CT', 0;
END

SELECT object_name, rows_found
FROM #res;

DROP TABLE #res;
