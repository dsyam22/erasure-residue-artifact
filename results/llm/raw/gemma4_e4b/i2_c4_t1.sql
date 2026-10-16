WITH CheckResults AS (
    -- Checking dbo.customer for residual PII data
    SELECT 
        'dbo.customer' AS object_name, 
        COUNT(*) AS rows_found
    FROM 
        dbo.customer
    WHERE 
        full_name = N'Subject_0000042' 
        AND email = N'subject42@example.invalid' 
        AND phone = N'+1-555-0000042'

    UNION ALL

    -- Checking dbo.customer_history for residual PII data
    SELECT 
        'dbo.customer_history' AS object_name, 
        COUNT(*) AS rows_found
    FROM 
        dbo.customer_history
    WHERE 
        full_name = N'Subject_0000042' 
        AND email = N'subject42@example.invalid' 
        AND phone = N'+1-555-0000042'
)
SELECT 
    object_name, 
    rows_found
FROM 
    CheckResults;
