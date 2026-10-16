-- SCRIPT
SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = 'Subject_0000042';
DECLARE @email nvarchar(255) = 'subject42@example.invalid';
DECLARE @phone nvarchar(255) = '+1-555-0000042';

SELECT 
    'dbo.customer' AS object_name,
    SUM(
        CASE 
            WHEN customer_id = @customer_id
              OR full_name = @full_name
              OR email = @email
              OR phone = @phone
            THEN 1 ELSE 0 
        END
    ) AS rows_found
FROM dbo.customer;
