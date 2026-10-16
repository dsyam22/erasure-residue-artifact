WITH CustomerCount AS (
    -- Check 1: The active customer table (dbo.customer)
    SELECT 
        'dbo.customer' AS object_name,
        COUNT(T.customer_id) AS rows_found
    FROM 
        dbo.customer T
    WHERE 
        T.customer_id = 42
        AND T.full_name = 'Subject_0000042'
        AND T.email = 'subject42@example.invalid'
        AND T.phone = '+1-555-0000042'

), HistoryCount AS (
    -- Check 2: The temporal history table (dbo.customer_history)
    SELECT 
        'dbo.customer_history' AS object_name,
        COUNT(T.customer_id) AS rows_found
    FROM 
        dbo.customer_history T
    WHERE 
        T.customer_id = 42
        AND T.full_name = 'Subject_0000042'
        AND T.email = 'subject42@example.invalid'
        AND T.phone = '+1-555-0000042'
)
-- Combine results into the required single result set
SELECT 
    object_name, 
    rows_found
FROM CustomerCount

UNION ALL

SELECT 
    object_name, 
    rows_found
FROM HistoryCount;
