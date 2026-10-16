WITH CheckCounts AS (
    -- 1. Check dbo.customer (Original Table)
    SELECT 'dbo.customer' AS object_name, 
           (SELECT COUNT(*) FROM dbo.customer WHERE customer_id = 42 OR full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042') AS rows_found
    UNION ALL
    -- 2. Check cdc.dbo_customer_CT (CDC Change Table)
    SELECT 'cdc.dbo_customer_CT',
           (SELECT COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id = 42 OR full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042')
    UNION ALL
    -- 3. Check dbo.member (Original Table)
    SELECT 'dbo.member',
           (SELECT COUNT(*) FROM dbo.member WHERE member_id = 42 OR full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042')
    UNION ALL
    -- 4. Check dbo.member_history (Temporal History Table)
    SELECT 'dbo.member_history',
           (SELECT COUNT(*) FROM dbo.member_history WHERE member_id = 42 OR full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042')
)
SELECT object_name, rows_found FROM CheckCounts;
