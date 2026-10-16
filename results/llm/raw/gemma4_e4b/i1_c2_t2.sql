WITH SourceChecks AS (
    -- Check 1: The primary table where the data was deleted
    SELECT
        'dbo.customer' AS object_name,
        COUNT(T1.customer_id) AS rows_found
    FROM
        dbo.customer T1
    WHERE
        T1.customer_id = 42
        AND T1.full_name = 'Subject_0000042'
        AND T1.email = 'subject42@example.invalid'
        AND T1.phone = '+1-555-0000042'

    UNION ALL

    -- Check 2: The CDC history table (where deleted records might persist)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(T2.customer_id) AS rows_found
    FROM
        cdc.dbo_customer_CT T2
    WHERE
        T2.customer_id = 42
        AND T2.full_name = 'Subject_0000042'
        AND T2.email = 'subject42@example.invalid'
        AND T2.phone = '+1-555-0000042'
)

SELECT
    object_name,
    rows_found
FROM
    SourceChecks;
