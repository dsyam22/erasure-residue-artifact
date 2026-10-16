WITH CheckResults AS (
    -- Check 1: dbo.customer table (The primary source)
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(1) AS INT) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

    UNION ALL

    -- Check 2: cdc.dbo_customer_CT (The Change Data Capture table)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        CAST(COUNT(1) AS INT) AS rows_found
    FROM
        cdc.dbo_customer_CT
    WHERE
        -- Note: We check for the presence of the data subject's details in the change capture table
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'
)
SELECT
    object_name,
    rows_found
FROM
    CheckResults;
