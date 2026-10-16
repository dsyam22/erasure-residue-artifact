WITH CheckResults AS
(
    -- 1. Check the live table (dbo.customer)
    SELECT
        N'dbo.customer' AS object_name,
        CAST(COUNT(customer_id) AS INT) AS rows_found
    FROM
        dbo.customer
    WHERE
        full_name = N'Subject_0000042'
        AND email = N'subject42@example.invalid'
        AND phone = N'+1-555-0000042'

    UNION ALL

    -- 2. Check the CDC change table (cdc.dbo_customer_CT)
    SELECT
        N'cdc.dbo_customer_CT' AS object_name,
        CAST(COUNT(customer_id) AS INT) AS rows_found
    FROM
        cdc.dbo_customer_CT
    WHERE
        -- Check if the subject data was captured in any of the primary columns
        full_name = N'Subject_0000042'
        AND email = N'subject42@example.invalid'
        AND phone = N'+1-555-0000042'
)
SELECT object_name, rows_found FROM CheckResults;
