SELECT
    'dbo.customer' AS object_name,
    CAST(COUNT(T.*) AS INT) AS rows_found
FROM
    dbo.customer T
WHERE
    T.customer_id = 42 OR
    T.full_name = 'Subject_0000042' OR
    T.email = 'subject42@example.invalid' OR
    T.phone = '+1-555-0000042';
