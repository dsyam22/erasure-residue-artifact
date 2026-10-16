WITH CheckResults AS (
    -- Checking dbo.customer table for residual data
    SELECT 
        'dbo.customer' AS object_name,
        COUNT(1) AS rows_found
    FROM 
        dbo.customer
    WHERE 
        customer_id = 42 
        AND full_name = 'Subject_0000042' 
        AND email = 'subject42@example.invalid' 
        AND phone = '+1-555-0000042'

    UNION ALL

    -- Checking dbo.customer_history table for residual data
    SELECT 
        'dbo.customer_history' AS object_name,
        COUNT(1) AS rows_found
    FROM 
        dbo.customer_history
    WHERE 
        customer_id = 42 
        AND full_name = 'Subject_0000042' 
        AND email = 'subject42@example.invalid' 
        AND phone = '+1-555-0000042'
)
SELECT object_name, rows_found FROM CheckResults ORDER BY object_name;
