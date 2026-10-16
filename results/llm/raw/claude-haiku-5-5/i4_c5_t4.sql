-- SCRIPT
SET NOCOUNT ON;

DECLARE @name  nvarchar(100)  = N'Subject_0000042';
DECLARE @email nvarchar(255)  = N'subject42@example.invalid';
DECLARE @phone nvarchar(50)   = N'+1-555-0000042';

SELECT object_name, rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*) FROM dbo.customer
             WHERE full_name = @name OR email = @email OR phone = @phone) AS rows_found
    UNION ALL
    SELECT N'dbo.member',
           (SELECT COUNT(*) FROM dbo.member
             WHERE full_name = @name OR email = @email OR phone = @phone)
    UNION ALL
    SELECT N'dbo.member_history',
           (SELECT COUNT(*) FROM dbo.member_history
             WHERE full_name = @name OR email = @email OR phone = @phone)
    UNION ALL
    SELECT N'cdc.dbo_customer_CT',
           (SELECT COUNT(*) FROM cdc.dbo_customer_CT
             WHERE full_name = @name OR email = @email OR phone = @phone)
) AS results
ORDER BY object_name;
