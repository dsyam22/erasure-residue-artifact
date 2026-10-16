-- SCRIPT
SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

SELECT object_name, SUM(rows_found) AS rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = @customer_id
      AND (
            full_name = @full_name
         OR email = @email
         OR phone = @phone
      )

    UNION ALL

    SELECT N'dbo.member' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.member
    WHERE member_id = @customer_id
      AND (
            full_name = @full_name
         OR email = @email
         OR phone = @phone
      )
) AS checks
GROUP BY object_name
ORDER BY object_name;
