/* Read-only verification: is the erased subject's personal data still stored anywhere? */
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

/* dbo.customer */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* Return exactly one result set */
SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
