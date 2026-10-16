WITH ObjectChecks AS (
    -- Check dbo.customer for residual PII data
    SELECT 
        'dbo.customer' AS object_name, 
        COUNT(1) AS rows_found
    FROM 
        dbo.customer
    WHERE 
        full_name = 'Subject_0000042' 
        OR email = 'subject42@example.invalid' 
        OR phone = '+1-555-0000042'
)
SELECT 
    object_name, 
    rows_found
FROM 
    ObjectChecks;
