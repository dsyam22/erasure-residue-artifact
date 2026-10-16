-- SCRIPT
DECLARE @cid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

SELECT 'dbo.customer' AS object_name,
       (SELECT COUNT(*)
        FROM dbo.customer AS c
        WHERE c.full_name = @name
           OR c.email = @email
           OR c.phone = @phone) AS rows_found
UNION ALL
SELECT 'dbo.customer_history' AS object_name,
       (SELECT COUNT(*)
        FROM dbo.customer_history AS h
        WHERE h.full_name = @name
           OR h.email = @email
           OR h.phone = @phone) AS rows_found;
