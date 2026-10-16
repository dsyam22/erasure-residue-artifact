WITH SourceData AS (
    -- Define the specific PII we are looking for
    SELECT 
        'Subject_0000042' AS target_full_name, 
        'subject42@example.invalid' AS target_email, 
        '+1-555-0000042' AS target_phone
),
CheckCounts AS (
    -- 1. dbo.customer (Current state)
    SELECT 
        CAST('dbo.customer' AS nvarchar(128)) AS object_name,
        ISNULL((
            SELECT COUNT(DISTINCT c.customer_id) 
            FROM dbo.customer c
            INNER JOIN SourceData sd ON 
                c.full_name = sd.target_full_name AND 
                c.email = sd.target_email AND 
                c.phone = sd.target_phone
        ), 0) AS rows_found
),
CheckCDC AS (
    -- 2. cdc.dbo_customer_CT (Change Data Capture Table)
    SELECT 
        CAST('cdc.dbo_customer_CT' AS nvarchar(128)) AS object_name,
        ISNULL((
            SELECT COUNT(DISTINCT customer_id) -- Counting distinct records that matched the original PII
            FROM cdc.dbo_customer_CT ct
            INNER JOIN SourceData sd ON 
                ct.full_name = sd.target_full_name AND 
                ct.email = sd.target_email AND 
                ct.phone = sd.target_phone
        ), 0) AS rows_found
),
CheckMemberCurrent AS (
    -- 3. dbo.member (Current state)
    SELECT 
        CAST('dbo.member' AS nvarchar(128)) AS object_name,
        ISNULL((
            SELECT COUNT(DISTINCT member_id)
            FROM dbo.member m
            INNER JOIN SourceData sd ON 
                m.full_name = sd.target_full_name AND 
                m.email = sd.target_email AND 
                m.phone = sd.target_phone
        ), 0) AS rows_found
),
CheckMemberHistory AS (
    -- 4. dbo.member_history (Temporal History Table)
    SELECT 
        CAST('dbo.member_history' AS nvarchar(128)) AS object_name,
        ISNULL((
            SELECT COUNT(DISTINCT member_id) -- Counting distinct records that matched the original PII in history
            FROM dbo.member_history mh
            INNER JOIN SourceData sd ON 
                mh.full_name = sd.target_full_name AND 
                mh.email = sd.target_email AND 
                mh.phone = sd.target_phone
        ), 0) AS rows_found
)
-- Combine all results into the required single result set structure
SELECT * FROM CheckCounts
UNION ALL
SELECT * FROM CheckCDC
UNION ALL
SELECT * FROM CheckMemberCurrent
UNION ALL
SELECT * FROM CheckMemberHistory;
