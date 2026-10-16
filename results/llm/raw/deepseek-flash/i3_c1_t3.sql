DECLARE @cid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (object_name nvarchar(257), rows_found bigint);

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM #results;

DROP TABLE #results;
