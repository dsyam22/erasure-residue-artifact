DECLARE @customer_id int = 42;
DECLARE @member_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

SELECT object_name, SUM(rows_found) AS rows_found
FROM
(
    SELECT N'dbo.customer' AS object_name, COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = @customer_id
       OR (full_name = @full_name AND email = @email AND phone = @phone)

    UNION ALL

    SELECT N'dbo.member' AS object_name, COUNT(*) AS rows_found
    FROM dbo.member
    WHERE member_id = @member_id
       OR (full_name = @full_name AND email = @email AND phone = @phone)

    UNION ALL

    SELECT N'dbo.member_history' AS object_name, COUNT(*) AS rows_found
    FROM dbo.member_history
    WHERE member_id = @member_id
       OR (full_name = @full_name AND email = @email AND phone = @phone)

    UNION ALL

    SELECT N'cdc.dbo_customer_CT' AS object_name, COUNT(*) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
       OR (full_name = @full_name AND email = @email AND phone = @phone)
) AS checks
GROUP BY object_name
ORDER BY object_name;
