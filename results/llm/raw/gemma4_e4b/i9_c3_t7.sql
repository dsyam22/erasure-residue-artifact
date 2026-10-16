WITH Check_Customer AS (
    -- Check 1: The active customer table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(CASE WHEN c.customer_id = 42 AND c.full_name = 'Subject_0000042' THEN 1 END) AS INT) AS rows_found
    FROM dbo.customer c
),
Check_History AS (
    -- Check 2: The temporal history table (dbo.customer_history)
    SELECT
        'dbo.customer_history' AS object_name,
        CAST(COUNT(CASE WHEN ch.customer_id = 42 AND ch.full_name = 'Subject_0000042' THEN 1 END) AS INT) AS rows_found
    FROM dbo.customer_history ch
),
-- Combine the results into a single set, ensuring all checked objects are represented.
FinalCheck (object_name, rows_found) AS (
    SELECT object_name, rows_found FROM Check_Customer
    UNION ALL
    SELECT object_name, rows_found FROM Check_History
)

-- Select the final structured result set
SELECT object_name, rows_found
FROM FinalCheck;
