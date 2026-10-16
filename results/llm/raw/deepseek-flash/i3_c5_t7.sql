-- SCRIPT
DECLARE @cid int = 42;
DECLARE @name nvarchar(100) = N'Subject_0000042';
DECLARE @email nvarchar(100) = N'subject42@example.invalid';
DECLARE @phone nvarchar(100) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM @results;
