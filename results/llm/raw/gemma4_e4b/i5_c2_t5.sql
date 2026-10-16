WITH CustomerCheck AS (
    -- Check 1: The current state table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(customer_id) AS INT) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = 42
),
HistoryCheck AS (
    -- Check 2: The temporal history table (dbo.customer_history)
    SELECT
        'dbo.customer_history' AS object_name,
        CAST(COUNT(customer_id) AS INT) AS rows_found
    FROM
        dbo.customer_history
    WHERE
        customer_id = 42
)
-- Combine the results into a single result set
SELECT object_name, rows_found FROM CustomerCheck
UNION ALL
SELECT object_name, rows_found FROM HistoryCheck;
