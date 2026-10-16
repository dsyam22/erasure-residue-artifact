SELECT
    CAST('dbo.customer' AS NVARCHAR(256)) AS object_name,
    COUNT(CASE WHEN c.customer_id = 42 AND c.full_name = 'Subject_0000042' AND c.email = 'subject42@example.invalid' AND c.phone = '+1-555-0000042' THEN 1 END) AS rows_found
FROM
    dbo.customer c;
