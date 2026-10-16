DECLARE @cid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(400) = N'subject42@example.invalid';
DECLARE @phone nvarchar(60) = N'+1-555-0000042';

SELECT object_name, SUM(rows_found) AS rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = @cid
       OR full_name = @name
       OR email = @email
       OR phone = @phone

    UNION ALL

    SELECT 'dbo.customer_history' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.customer_history
    WHERE customer_id = @cid
       OR full_name = @name
       OR email = @email
       OR phone = @phone
) AS checks
GROUP BY object_name;
