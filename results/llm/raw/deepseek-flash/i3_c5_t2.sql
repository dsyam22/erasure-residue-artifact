-- SCRIPT
SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

;WITH checks AS
(
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*)
            FROM dbo.customer
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone) AS rows_found

    UNION ALL

    SELECT N'dbo.member' AS object_name,
           (SELECT COUNT(*)
            FROM dbo.member
            WHERE member_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone) AS rows_found
)
SELECT object_name, rows_found
FROM checks;
