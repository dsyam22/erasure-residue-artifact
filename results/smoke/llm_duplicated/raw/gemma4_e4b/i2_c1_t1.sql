SELECT
    'dbo.customer' AS object_name,
    CAST(COUNT(T1.*) AS INT) AS rows_found
FROM
    dbo.customer T1
WHERE
    T1.customer_id = 42 OR
    T1.full_name = 'Subject_0000042' OR
    T1.email = 'subject42@example.invalid' OR
    T1.phone = '+1-555-0000042';
