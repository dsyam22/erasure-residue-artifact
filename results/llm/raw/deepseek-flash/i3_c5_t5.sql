-- SCRIPT
DECLARE @cid int = 42;
DECLARE @mid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

SELECT object_name, rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = @cid
       OR full_name = @name
       OR email = @email
       OR phone = @phone

    UNION ALL

    SELECT 'dbo.member' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.member
    WHERE member_id = @mid
       OR full_name = @name
       OR email = @email
       OR phone = @phone
) AS results;
