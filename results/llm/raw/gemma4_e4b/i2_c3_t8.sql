WITH CheckedObjects AS (
    -- Check 1: Current state of the table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(*) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = 42

    UNION ALL

    -- Check 2: Temporal history records (dbo.customer_history)
    SELECT
        'dbo.customer_history' AS object_name,
        COUNT(*) AS rows_found
    FROM
        dbo.customer_history
    WHERE
        customer_id = 42
)
SELECT * FROM CheckedObjects;
