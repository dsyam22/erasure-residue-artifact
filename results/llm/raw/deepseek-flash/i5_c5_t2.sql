-- SCRIPT
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

-- Check dbo.customer for any remaining rows matching the subject's original personal data
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
