SELECT
    'dbo.customer' AS object_name,
    CAST(COUNT(1) AS INT) AS rows_found
FROM
    dbo.customer
WHERE
    customer_id = 42
    AND full_name = 'Subject_0000042'
    AND email = 'subject42@example.invalid'
    AND phone = '+1-555-0000042';
