-- SCRIPT
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @full nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

;WITH checks AS (
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*) FROM dbo.customer
            WHERE customer_id = @cid
               OR full_name = @full
               OR email = @email
               OR phone = @phone) AS rows_found
)
SELECT object_name, rows_found
FROM checks
ORDER BY object_name;
