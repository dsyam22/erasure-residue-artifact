WITH ObjectCounts AS (
    -- Check 1: The primary table (dbo.customer) - Should be zero after DELETE
    SELECT
        'dbo.customer' AS object_name,
        COUNT(T.*) AS rows_found
    FROM
        dbo.customer T
    WHERE
        T.customer_id = 42 OR T.full_name = 'Subject_0000042' OR T.email = 'subject42@example.invalid' OR T.phone = '+1-555-0000042'

    UNION ALL

    -- Check 2: The temporal history table (dbo.customer_history) - Where deleted data persists
    SELECT
        'dbo.customer_history',
        COUNT(T.*)
    FROM
        dbo.customer_history T
    WHERE
        T.customer_id = 42 OR T.full_name = 'Subject_0000042' OR T.email = 'subject42@example.invalid' OR T.phone = '+1-555-0000042'

    -- No other objects need checking as CDC is disabled and no other tables were mentioned
)
SELECT
    object_name,
    rows_found
FROM
    ObjectCounts;
