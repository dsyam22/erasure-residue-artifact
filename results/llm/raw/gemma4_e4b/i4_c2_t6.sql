WITH CheckResults AS (
    -- 1. dbo.customer check
    SELECT 
        'dbo.customer' AS object_name, 
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.customer WHERE customer_id = 42

    UNION ALL

    -- 2. dbo.member check (Primary versioned table)
    SELECT 
        'dbo.member' AS object_name, 
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.member WHERE member_id = 42

    UNION ALL

    -- 3. dbo.member_history check (History table)
    SELECT 
        'dbo.member_history' AS object_name, 
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.member_history WHERE member_id = 42

    UNION ALL

    -- 4. cdc.dbo_customer_CT check (Change Tracking table)
    SELECT 
        'cdc.dbo_customer_CT' AS object_name, 
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM cdc.dbo_customer_CT WHERE customer_id = 42
)
SELECT object_name, rows_found FROM CheckResults;
