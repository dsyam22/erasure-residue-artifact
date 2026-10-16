SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @fname nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname NOT NULL, rows_found int NOT NULL);

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @fname
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
