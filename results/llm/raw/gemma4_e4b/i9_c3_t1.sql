WITH CheckResults AS (
    -- 1. Check the current state table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(T.customer_id) AS rows_found
    FROM
        dbo.customer AS T
    WHERE
        T.customer_id = 42

    UNION ALL

    -- 2. Check the system-versioned history table (dbo.customer_history)
    SELECT
        'dbo.customer_history' AS object_name,
        COUNT(T.customer_id) AS rows_found
    FROM
        dbo.customer_history AS T
    WHERE
        T.customer_id = 42
)
SELECT
    object_name,
    rows_found
FROM
    CheckResults;
