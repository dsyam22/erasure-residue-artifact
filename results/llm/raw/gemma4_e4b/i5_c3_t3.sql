WITH CheckResults AS (
    -- 1. Primary Table Check (dbo.customer) - Checks if data exists in current/live records
    SELECT
        'dbo.customer' AS object_name,
        ISNULL(COUNT(*), 0) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

    UNION ALL

    -- 2. Temporal History Table Check (dbo.customer_history) - Checks for records deleted from the live table
    SELECT
        'dbo.customer_history' AS object_name,
        ISNULL(COUNT(*), 0) AS rows_found
    FROM
        dbo.customer_history
    WHERE
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

    /*
     * Note: CDC is disabled (cdc_enabled=0), so no explicit check against cdc change tables is needed.
     * No other downstream copies were provided in the schema definition, so only the two primary locations are checked.
     */
)
SELECT object_name, rows_found FROM CheckResults;
