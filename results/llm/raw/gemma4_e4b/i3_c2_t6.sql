WITH CheckResults AS (
    -- 1. dbo.customer (Current state check)
    SELECT 
        'dbo.customer' AS object_name,
        CAST(ISNULL((SELECT COUNT(*) FROM dbo.customer WHERE customer_id = 42 AND full_name = 'Subject_0000042'), 0) AS INT) AS rows_found
),
CDCCheckResults AS (
    -- 2. cdc.dbo_customer_CT (CDC Change Table check - checking for the ID existence is sufficient)
    SELECT 
        'cdc.dbo_customer_CT' AS object_name,
        CAST(ISNULL((SELECT COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id = 42), 0) AS INT) AS rows_found
),
MemberCurrentCheck AS (
    -- 3. dbo.member (Current state check for temporal table)
    SELECT 
        'dbo.member' AS object_name,
        CAST(ISNULL((SELECT COUNT(*) FROM dbo.member WHERE member_id = 42 AND full_name = 'Subject_0000042'), 0) AS INT) AS rows_found
),
MemberHistoryCheck AS (
    -- 4. dbo.member_history (Temporal History Check)
    SELECT 
        'dbo.member_history' AS object_name,
        CAST(ISNULL((
            SELECT COUNT(*) FROM dbo.member_history 
            WHERE member_id = 42 
              AND full_name = 'Subject_0000042' 
              AND email = 'subject42@example.invalid'
              AND phone = '+1-555-0000042'
        ), 0) AS INT) AS rows_found
)
-- Combine all results into a single result set
SELECT * FROM CheckResults
UNION ALL
SELECT * FROM CDCCheckResults
UNION ALL
SELECT * FROM MemberCurrentCheck
UNION ALL
SELECT * FROM MemberHistoryCheck;
