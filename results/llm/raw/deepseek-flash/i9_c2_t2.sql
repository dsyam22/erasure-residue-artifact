SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

SELECT object_name, rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           (SELECT COUNT(*)
              FROM dbo.customer
             WHERE customer_id = @customer_id
                OR full_name = @full_name
                OR email = @email
                OR phone = @phone) AS rows_found
    UNION ALL
    SELECT 'dbo.customer_history',
           (SELECT COUNT(*)
              FROM dbo.customer_history
             WHERE customer_id = @customer_id
                OR full_name = @full_name
                OR email = @email
                OR phone = @phone)
) AS checks
ORDER BY object_name;
