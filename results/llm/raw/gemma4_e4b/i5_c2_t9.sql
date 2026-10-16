SELECT 
    object_name, 
    rows_found 
FROM 
(
    -- Check 1: Primary Table (dbo.customer)
    SELECT 
        'dbo.customer' AS object_name, 
        CAST(COUNT(DISTINCT customer_id) AS INT) AS rows_found
    FROM 
        dbo.customer
    WHERE 
        customer_id = 42 OR 
        full_name = N'Subject_0000042' OR 
        email = N'subject42@example.invalid' OR 
        phone = N'+1-555-0000042'

    UNION ALL

    -- Check 2: History Table (dbo.customer_history)
    SELECT 
        'dbo.customer_history' AS object_name, 
        CAST(COUNT(DISTINCT customer_id) AS INT) AS rows_found
    FROM 
        dbo.customer_history
    WHERE 
        customer_id = 42 OR 
        full_name = N'Subject_0000042' OR 
        email = N'subject42@example.invalid' OR 
        phone = N'+1-555-0000042'

) AS VerificationResults;
