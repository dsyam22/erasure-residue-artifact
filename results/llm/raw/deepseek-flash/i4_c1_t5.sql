SET NOCOUNT ON;

DECLARE @full_name nvarchar(400) = N'Subject_0000042';
DECLARE @email nvarchar(400) = N'subject42@example.invalid';
DECLARE @phone nvarchar(400) = N'+1-555-0000042';
DECLARE @customer_id int = 42;
DECLARE @member_id int = 42;

CREATE TABLE #results (object_name sysname, rows_found int);

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
      );

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @member_id
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
      );

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
