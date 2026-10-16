SELECT
    object_name,
    rows_found
FROM
(
    -- Check dbo.customer for original personal data
    SELECT 
        'dbo.customer' AS object_name, 
        COUNT(1) AS rows_found
    FROM 
        dbo.customer
    WHERE 
        full_name = 'Subject_0000042' OR 
        email = 'subject42@example.invalid' OR 
        phone = '+1-555-0000042'

    UNION ALL

    -- Check dbo.member for original personal data
    SELECT 
        'dbo.member' AS object_name, 
        COUNT(1) AS rows_found
    FROM 
        dbo.member
    WHERE 
        full_name = 'Subject_0000042' OR 
        email = 'subject42@example.invalid' OR 
        phone = '+1-555-0000042'
) AS VerificationResults;
