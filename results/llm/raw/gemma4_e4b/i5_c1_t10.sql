WITH CheckResults AS (
    -- Count any records in dbo.customer that match the subject's identifiers
    SELECT 
        COUNT(1) AS FoundCount
    FROM 
        dbo.customer
    WHERE 
        customer_id = 42 
        OR full_name = 'Subject_0000042' 
        OR email = 'subject42@example.invalid' 
        OR phone = '+1-555-0000042'
)
SELECT 
    CAST('dbo.customer' AS NVARCHAR(128)) AS object_name,
    T1.FoundCount AS rows_found
FROM 
    CheckResults T1;
