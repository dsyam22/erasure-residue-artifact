WITH CustomerCounts AS (
    -- Check the current primary table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(1) AS rows_found
    FROM dbo.customer
    WHERE full_name = 'Subject_0000042' 
       OR email = 'subject42@example.invalid' 
       OR phone = '+1-555-0000042'
),
HistoryCounts AS (
    -- Check the temporal history table (dbo.customer_history)
    SELECT
        'dbo.customer_history' AS object_name,
        COUNT(1) AS rows_found
    FROM dbo.customer_history
    WHERE full_name = 'Subject_0000042' 
       OR email = 'subject42@example.invalid' 
       OR phone = '+1-555-0000042'
)
-- Combine results into a single required output set
SELECT object_name, rows_found FROM CustomerCounts
UNION ALL
SELECT object_name, rows_found FROM HistoryCounts;
