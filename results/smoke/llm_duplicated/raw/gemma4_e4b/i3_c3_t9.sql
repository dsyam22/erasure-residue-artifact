WITH CheckResults AS (
    -- 1. dbo.customer (Current state)
    SELECT 'dbo.customer' AS object_name, COUNT(T.*) AS rows_found
    FROM dbo.customer T
    WHERE T.full_name = 'Subject_0000042' OR T.email = 'subject42@example.invalid' OR T.phone = '+1-555-0000042'

    UNION ALL

    -- 2. cdc.dbo_customer_CT (CDC Change Table)
    SELECT 'cdc.dbo_customer_CT', COUNT(T.*)
    FROM cdc.dbo_customer_CT T
    WHERE T.full_name = 'Subject_0000042' OR T.email = 'subject42@example.invalid' OR T.phone = '+1-555-0000042'

    UNION ALL

    -- 3. dbo.member (Current state)
    SELECT 'dbo.member', COUNT(T.*)
    FROM dbo.member T
    WHERE T.full_name = 'Subject_0000042' OR T.email = 'subject42@example.invalid' OR T.phone = '+1-555-0000042'

    UNION ALL

    -- 4. dbo.member_history (Temporal History Table)
    SELECT 'dbo.member_history', COUNT(T.*)
    FROM dbo.member_history T
    WHERE T.full_name = 'Subject_0000042' OR T.email = 'subject42@example.invalid' OR T.phone = '+1-555-0000042'
)
SELECT object_name, rows_found FROM CheckResults;
