-- SCRIPT
SET NOCOUNT ON;

DECLARE @needle_full  nvarchar(200) = N'Subject_0000042';
DECLARE @needle_email nvarchar(200) = N'subject42@example.invalid';
DECLARE @needle_phone nvarchar(200) = N'+1-555-0000042';
DECLARE @needle_id    int           = 42;

SELECT object_name, rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*)
            FROM dbo.customer
            WHERE customer_id = @needle_id
               OR full_name = @needle_full
               OR email = @needle_email
               OR phone = @needle_phone) AS rows_found
) AS results
ORDER BY object_name;
