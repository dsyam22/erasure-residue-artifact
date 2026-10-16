WITH ObjectChecks AS (
    -- Check the current state of the primary table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        (SELECT COUNT(*) FROM dbo.customer WHERE customer_id = 42 AND full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042') AS rows_found
),
HistoryCheck AS (
    -- Check the temporal history table (dbo.customer_history)
    SELECT
        'dbo.customer_history' AS object_name,
        (SELECT COUNT(*) FROM dbo.customer_history WHERE customer_id = 42 AND full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042') AS rows_found
)
-- Combine the results into a single output set
SELECT 
    object_name, 
    rows_found
FROM ObjectChecks

UNION ALL

SELECT 
    object_name, 
    rows_found
FROM HistoryCheck;
