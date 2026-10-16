WITH SearchResults AS (
    -- 1. Check dbo.customer (Live Table)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(customer_id) AS rows_found
    FROM
        dbo.customer
    WHERE
        full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

    UNION ALL

    -- 2. Check cdc.dbo_customer_CT (Customer CDC Change Table)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(customer_id) AS rows_found
    FROM
        cdc.dbo_customer_CT
    WHERE
        -- Note: We check the captured columns for consistency even if they might represent deletes (is_deleted = 1)
        full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

    UNION ALL

    -- 3. Check dbo.member (Live Table - System Versioned Temporal)
    SELECT
        'dbo.member' AS object_name,
        COUNT(member_id) AS rows_found
    FROM
        dbo.member
    WHERE
        full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

    UNION ALL

    -- 4. Check dbo.member_history (History Table)
    SELECT
        'dbo.member_history' AS object_name,
        COUNT(member_id) AS rows_found
    FROM
        dbo.member_history
    WHERE
        full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'
)
SELECT
    object_name,
    rows_found
FROM
    SearchResults;
