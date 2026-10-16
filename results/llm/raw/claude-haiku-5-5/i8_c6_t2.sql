-- SCRIPT
SELECT
    CAST('dbo.customer' AS nvarchar(256)) AS object_name,
    CAST((
        SELECT COUNT(*)
        FROM dbo.customer AS c
        WHERE c.customer_id = 42
           OR c.full_name = N'Subject_0000042'
           OR c.email = N'subject42@example.invalid'
           OR c.phone = N'+1-555-0000042'
    ) AS int) AS rows_found;
