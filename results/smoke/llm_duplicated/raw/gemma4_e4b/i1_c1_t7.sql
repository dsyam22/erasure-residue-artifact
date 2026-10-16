SELECT
    'dbo.customer' AS object_name,
    CAST(COUNT(*) AS INT) AS rows_found
FROM dbo.customer
WHERE 
    full_name = 'Subject_0000042'
    OR email = 'subject42@example.invalid'
    OR phone = '+1-555-0000042';
