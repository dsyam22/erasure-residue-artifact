WITH CheckResults AS (
    -- 1. Check dbo.customer table (Current state)
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(T.customer_id) AS INT) AS rows_found
    FROM
        dbo.customer AS T
    WHERE
        T.full_name = 'Subject_0000042' 
        AND T.email = 'subject42@example.invalid' 
        AND T.phone = '+1-555-0000042'

    UNION ALL

    -- 2. Check dbo.member table (Current state)
    SELECT
        'dbo.member' AS object_name,
        CAST(COUNT(T.member_id) AS INT) AS rows_found
    FROM
        dbo.member AS T
    WHERE
        T.full_name = 'Subject_0000042' 
        AND T.email = 'subject42@example.invalid' 
        AND T.phone = '+1-555-0000042'

    UNION ALL

    -- 3. Check dbo.member_history table (Temporal history)
    SELECT
        'dbo.member_history' AS object_name,
        CAST(COUNT(T.member_id) AS INT) AS rows_found
    FROM
        dbo.member_history AS T
    WHERE
        T.full_name = 'Subject_0000042' 
        AND T.email = 'subject42@example.invalid' 
        AND T.phone = '+1-555-0000042'
)
SELECT object_name, rows_found FROM CheckResults;
