-- SCRIPT
SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @member_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

SELECT object_name, rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*) FROM dbo.customer
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone) AS rows_found
    UNION ALL
    SELECT N'dbo.member' AS object_name,
           (SELECT COUNT(*) FROM dbo.member
            WHERE member_id = @member_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone) AS rows_found
    UNION ALL
    SELECT N'dbo.member_history' AS object_name,
           (SELECT COUNT(*) FROM dbo.member_history
            WHERE member_id = @member_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone) AS rows_found
    UNION ALL
    SELECT N'cdc.dbo_customer_CT' AS object_name,
           (SELECT COUNT(*) FROM cdc.dbo_customer_CT
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone) AS rows_found
) AS checks
ORDER BY object_name;
