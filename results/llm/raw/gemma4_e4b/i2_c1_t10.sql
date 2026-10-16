SELECT
    'dbo.customer' AS object_name,
    (
        -- Use a COUNT(*) subquery to determine if any residual records matching the PII exist.
        SELECT COUNT(1)
        FROM dbo.customer c
        WHERE 
            c.full_name = 'Subject_0000042' 
            OR c.email = 'subject42@example.invalid' 
            OR c.phone = '+1-555-0000042'
    ) AS rows_found;
