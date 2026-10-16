SELECT object_name, rows_found FROM (
    -- 1. Check the primary customer table
    SELECT
        'dbo.customer' AS object_name,
        COUNT(customer_id) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

    UNION ALL

    -- 2. Check the Change Data Capture (CDC) history table
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(customer_id) AS rows_found
    FROM
        cdc.dbo_customer_CT
    WHERE
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

) AS verification_results;
