-- SCRIPT
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @name nvarchar(400) = N'Subject_0000042';
DECLARE @email nvarchar(400) = N'subject42@example.invalid';
DECLARE @phone nvarchar(400) = N'+1-555-0000042';

SELECT object_name, rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           (SELECT COUNT(*)
            FROM dbo.customer
            WHERE customer_id = @cid
               OR full_name = @name
               OR email = @email
               OR phone = @phone) AS rows_found
) AS checks;
