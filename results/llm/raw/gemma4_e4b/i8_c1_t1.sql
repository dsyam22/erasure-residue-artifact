SELECT
    CAST('dbo.customer' AS varchar(256)) AS object_name,
    COUNT(CASE WHEN T1.customer_id = 42 OR T1.full_name = 'Subject_0000042' OR T1.email = 'subject42@example.invalid' OR T1.phone = '+1-555-0000042' THEN 1 END) AS rows_found
FROM
    dbo.customer AS T1;
