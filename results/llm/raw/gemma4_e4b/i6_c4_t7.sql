WITH CheckResults AS (
    SELECT 
        CAST('dbo.customer' AS sysname) AS object_name,
        COUNT(T1.customer_id) AS rows_found
    FROM dbo.customer T1
    WHERE 
        -- Check if the phone number is mentioned in the full_name field (residual data)
        T1.full_name LIKE '%+1-555-0000042%'
        OR 
        -- Check if the phone number is mentioned in the email field (residual data)
        T1.email LIKE '%+1-555-0000042%'
)
SELECT 
    object_name, 
    COALESCE(rows_found, 0) AS rows_found
FROM CheckResults;
