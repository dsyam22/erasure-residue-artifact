WITH SearchResults AS (
    -- Check the current live table version
    SELECT 
        'dbo.customer' AS object_name, 
        COUNT(1) AS rows_found
    FROM 
        dbo.customer
    WHERE 
        customer_id = 42

    UNION ALL

    -- Check the system-versioned history table for prior versions of the data
    SELECT 
        'dbo.customer_history' AS object_name, 
        COUNT(1) AS rows_found
    FROM 
        dbo.customer_history
    WHERE 
        customer_id = 42
)
SELECT 
    object_name, 
    rows_found
FROM 
    SearchResults;
