WITH ObjectCounts AS (
    -- 1. Check dbo.customer (Current State)
    SELECT
        'dbo.customer' AS object_name,
        (SELECT COUNT(*) FROM dbo.customer WHERE customer_id = 42 AND full_name = 'Subject_0000042') AS rows_found
),
CDCCounts AS (
    -- 2. Check CDC Change Table (cdc.dbo_customer_CT)
    -- We check if the original data was captured in any change record for customer_id 42.
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        (
            SELECT COUNT(DISTINCT * ) -- Counting distinct records where original data is present
            FROM cdc.dbo_customer_CT CT
            WHERE (
                -- Check if the old value captured matches any of the original fields
                ISNULL(CT.full_name_insured, '') = 'Subject_0000042' OR 
                ISNULL(CT.email_insured, '') = 'subject42@example.invalid' OR 
                ISNULL(CT.phone_insured, '') = '+1-555-0000042'
            )
        ) AS rows_found
),
MemberCounts AS (
    -- 3. Check dbo.member (Current State)
    SELECT
        'dbo.member' AS object_name,
        (SELECT COUNT(*) FROM dbo.member WHERE member_id = 42 AND full_name = 'Subject_0000042') AS rows_found
),
HistoryCounts AS (
    -- 4. Check dbo.member_history (Temporal History)
    SELECT
        'dbo.member_history' AS object_name,
        (
            SELECT COUNT(*)
            FROM dbo.member_history M
            WHERE M.member_id = 42 AND (
                M.full_name = 'Subject_0000042' OR 
                M.email = 'subject42@example.invalid' OR 
                M.phone = '+1-555-0000042'
            )
        ) AS rows_found
)
-- Combine all results into the required single result set structure
SELECT
    object_name,
    CAST(rows_found AS INT) AS rows_found
FROM ObjectCounts

UNION ALL

SELECT
    object_name,
    CAST(rows_found AS INT)
FROM CDCCounts

UNION ALL

SELECT
    object_name,
    CAST(rows_found AS INT)
FROM MemberCounts

UNION ALL

SELECT
    object_name,
    CAST(rows_found AS INT)
FROM HistoryCounts;
