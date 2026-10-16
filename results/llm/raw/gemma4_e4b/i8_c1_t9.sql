WITH SearchResults AS (
    -- Count records in dbo.customer that match any identifying piece of the subject's data
    SELECT 
        COUNT(T1.*) AS FoundCount
    FROM 
        dbo.customer AS T1
    WHERE 
        -- We check for potential remnants across multiple columns using OR logic
        T1.full_name = 'Subject_0000042' 
        OR T1.email = 'subject42@example.invalid' 
        OR T1.phone = '+1-555-0000042'
)
SELECT
    CAST('dbo.customer' AS NVARCHAR(128)) AS object_name,
    ISNULL(SR.FoundCount, 0) AS rows_found
FROM SearchResults SR;
