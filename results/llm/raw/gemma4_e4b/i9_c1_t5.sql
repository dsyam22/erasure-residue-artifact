SELECT
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM
    dbo.customer
WHERE
    full_name = 'Subject_0000042'
    AND email = 'subject42@example.invalid'
    AND phone = '+1-555-0000042';
