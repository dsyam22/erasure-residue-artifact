SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

SELECT object_name, rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           COUNT_BIG(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone
) AS r;
