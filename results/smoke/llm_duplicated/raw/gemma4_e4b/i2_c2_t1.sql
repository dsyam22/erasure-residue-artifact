WITH ObjectChecks AS (
    -- Check 1: The active table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(1) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

    UNION ALL

    -- Check 2: The history table (dbo.customer_history)
    SELECT
        'dbo.customer_history' AS object_name,
        COUNT(1) AS rows_found
    FROM
        dbo.customer_history
    WHERE
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'
)
SELECT object_name, rows_found FROM ObjectChecks;
