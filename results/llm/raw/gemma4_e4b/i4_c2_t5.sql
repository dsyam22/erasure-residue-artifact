WITH CheckResults AS (
    -- 1. dbo.customer (Current State)
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(CASE WHEN c.full_name = 'Subject_0000042' AND c.email = 'subject42@example.invalid' AND c.phone = '+1-555-0000042' THEN 1 END) AS INT) AS rows_found
    FROM dbo.customer c
    WHERE c.customer_id = 42

    UNION ALL

    -- 2. cdc.dbo__customer_CT (Change Tracking Table for Customer)
    SELECT
        'cdc.dbo__customer_CT' AS object_name,
        CAST(COUNT(CASE WHEN ctc.full_name = 'Subject_0000042' AND ctc.email = 'subject42@example.invalid' AND ctc.phone = '+1-555-0000042' THEN 1 END) AS INT)
    FROM cdc.dbo__customer_CT ctc
    WHERE ctc.customer_id = 42

    UNION ALL

    -- 3. dbo.member (Current State - Temporal Primary)
    SELECT
        'dbo.member' AS object_name,
        CAST(COUNT(CASE WHEN m.full_name = 'Subject_0000042' AND m.email = 'subject42@example.invalid' AND m.phone = '+1-555-0000042' THEN 1 END) AS INT)
    FROM dbo.member m
    WHERE m.member_id = 42

    UNION ALL

    -- 4. dbo.member_history (History Table - Temporal History)
    SELECT
        'dbo.member_history' AS object_name,
        CAST(COUNT(CASE WHEN mh.full_name = 'Subject_0000042' AND mh.email = 'subject42@example.invalid' AND mh.phone = '+1-555-0000042' THEN 1 END) AS INT)
    FROM dbo.member_history mh
    WHERE mh.member_id = 42
)

-- Final selection to ensure exactly two columns and one result set, handling the column type mismatch from UNION ALL (which defaults to NVARCHAR/VARCHAR for object_name).
SELECT
    object_name,
    rows_found
FROM CheckResults;
