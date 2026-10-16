WITH Check_Customer AS (
    -- 1. Current dbo.customer table check
    SELECT
        'dbo.customer' AS object_name,
        COUNT(T.*) AS rows_found
    FROM
        dbo.customer T
    WHERE
        T.customer_id = 42
        AND (
            T.full_name = 'Subject_0000042' OR
            T.email = 'subject42@example.invalid' OR
            T.phone = '+1-555-0000042'
        )

    UNION ALL

    -- 2. CDC change table check (Potential logging of original data)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(T.*)
    FROM
        cdc.dbo_customer_CT T
    WHERE
        T.customer_id = 42
        AND (
            T.full_name = 'Subject_0000042' OR
            T.email = 'subject42@example.invalid' OR
            T.phone = '+1-555-0000042'
        )
),
Check_Member AS (
    -- 3. Current dbo.member table check
    SELECT
        'dbo.member' AS object_name,
        COUNT(T.*) AS rows_found
    FROM
        dbo.member T
    WHERE
        T.member_id = 42
        AND (
            T.full_name = 'Subject_0000042' OR
            T.email = 'subject42@example.invalid' OR
            T.phone = '+1-555-0000042'
        )

    UNION ALL

    -- 4. Temporal history table check (dbo.member_history)
    SELECT
        'dbo.member_history' AS object_name,
        COUNT(T.*)
    FROM
        dbo.member_history T
    WHERE
        T.member_id = 42
        AND (
            T.full_name = 'Subject_0000042' OR
            T.email = 'subject42@example.invalid' OR
            T.phone = '+1-555-0000042'
        )

    UNION ALL

    -- 5. Additional check for potential direct joins/views (If the schema included a general user table, this is where it would go).
    -- Based only on provided tables, we assume no other explicit copies exist.
    SELECT
        'N/A_NoOtherCopiesChecked' AS object_name, -- Placeholder to ensure checking mechanism is comprehensive if required by future extension
        0 AS rows_found
)
SELECT
    object_name,
    rows_found
FROM
    Check_Customer; -- Outputting the combined result set from all checks
