SELECT
    'dbo.customer' AS object_name,
    COUNT(CASE WHEN T1.customer_id = 42 AND T1.full_name = 'Subject_0000042' AND T1.email = 'subject42@example.invalid' AND T1.phone = '+1-555-0000042' THEN 1 END) AS rows_found
FROM
    dbo.customer AS T1;
