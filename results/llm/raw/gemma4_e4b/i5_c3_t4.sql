WITH Check_Customer AS (
    -- Check the current, live table state (should be zero after DELETE)
    SELECT 
        CAST('dbo.customer' AS nvarchar) AS object_name,
        COUNT(1) AS rows_found
    FROM dbo.customer
    WHERE customer_id = 42 
      AND full_name = 'Subject_0000042' 
      AND email = 'subject42@example.invalid' 
      AND phone = '+1-555-0000042'
),
Check_History AS (
    -- Check the system versioned history table where deleted records reside
    SELECT 
        CAST('dbo.customer_history' AS nvarchar) AS object_name,
        COUNT(1) AS rows_found
    FROM dbo.customer_history
    WHERE customer_id = 42 
      AND full_name = 'Subject_0000042' 
      AND email = 'subject42@example.invalid' 
      AND phone = '+1-555-0000042'
)
-- Combine the results into a single required result set
SELECT 
    T1.object_name, 
    ISNULL(T1.rows_found, 0) AS rows_found
FROM Check_Customer T1

UNION ALL

SELECT 
    T2.object_name, 
    ISNULL(T2.rows_found, 0) AS rows_found
FROM Check_History T2;
