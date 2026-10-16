-- SCRIPT
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @full nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

-- dbo.customer: check all personal-data columns against the subject's original values
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @full
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found FROM @results;
