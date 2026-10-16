WITH Check_Customer AS (
    -- 1. Check dbo.customer table itself
    SELECT COUNT(CASE WHEN c.full_name = N'Subject_0000042' AND c.email = N'subject42@example.invalid' THEN 1 END) AS count_customer, 'dbo.customer' AS object_name
),
Check_CDC_Customer AS (
    -- 2. Check CDC Change Table for dbo.customer
    SELECT COUNT(CASE WHEN ct.customer_id = 42 AND ct.full_name LIKE N'%Subject%' THEN 1 END) AS count_cdc, 'cdc.dbo_customer_CT' AS object_name
),
Check_Member AS (
    -- 3. Check dbo.member table itself
    SELECT COUNT(CASE WHEN m.full_name = N'Subject_0000042' AND m.email = N'subject42@example.invalid' THEN 1 END) AS count_member, 'dbo.member' AS object_name
),
Check_Member_History AS (
    -- 4. Check dbo.member_history for the subject's historical record
    SELECT COUNT(CASE WHEN mhi.full_name = N'Subject_0000042' AND mhi.email = N'subject42@example.invalid' THEN 1 END) AS count_history, 'dbo.member_history' AS object_name
)
-- Combine results into the required single result set format
SELECT
    c.object_name,
    ISNULL(c.count_customer, 0) AS rows_found
FROM Check_Customer c

UNION ALL

SELECT
    cdc.object_name,
    ISNULL(cdc.count_cdc, 0) AS rows_found
FROM Check_CDC_Customer cdc

UNION ALL

SELECT
    m.object_name,
    ISNULL(m.count_member, 0) AS rows_found
FROM Check_Member m

UNION ALL

SELECT
    h.object_name,
    ISNULL(h.count_history, 0) AS rows_found
FROM Check_Member_History h;
