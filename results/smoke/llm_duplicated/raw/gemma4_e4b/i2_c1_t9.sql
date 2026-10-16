WITH CheckResults AS (
    -- Check dbo.customer for residual personal data leakage
    SELECT 
        COUNT(T1.customer_id) AS found_count
    FROM 
        dbo.customer T1
    WHERE 
            T1.full_name = 'Subject_0000042'
        OR T1.email = 'subject42@example.invalid'
        OR T1.phone = '+1-555-0000042'
)
SELECT 
    'dbo.customer' AS object_name, 
    (SELECT found_count FROM CheckResults) AS rows_found;
