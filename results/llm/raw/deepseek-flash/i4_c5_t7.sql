-- SCRIPT
SET NOCOUNT ON;

DECLARE @orig_name  nvarchar(200) = N'Subject_0000042';
DECLARE @orig_email nvarchar(200) = N'subject42@example.invalid';
DECLARE @orig_phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found int);

-- dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
  AND (
        full_name = @orig_name
     OR email     = @orig_email
     OR phone     = @orig_phone
      );

-- dbo.member
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member',
       COUNT(*)
FROM dbo.member
WHERE member_id = 42
  AND (
        full_name = @orig_name
     OR email     = @orig_email
     OR phone     = @orig_phone
      );

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
