WITH CheckResults AS (
    -- Count how many rows match all criteria in dbo.customer
    SELECT 
        COUNT(*) AS FoundCount
    FROM 
        dbo.customer
    WHERE 
        customer_id = 42 
        AND full_name = 'Subject_0000042' 
        AND email = 'subject42@example.invalid' 
        AND phone = '+1-555-0000042'
)
-- Select the required output format: object name and row count
SELECT 
    CAST('dbo.customer' AS NVARCHAR(256)) AS object_name,
    CR.FoundCount AS rows_found
FROM 
    CheckResults CR;
