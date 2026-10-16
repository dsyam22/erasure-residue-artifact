SELECT object_name, rows_found FROM (
    -- 1. Check dbo.customer (Main Table)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.customer

    UNION ALL

    -- 2. Check dbo.member (Main Temporal Table)
    SELECT
        'dbo.member' AS object_name,
        COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.member

    UNION ALL

    -- 3. Check cdc.dbo_customer_CT (CDC Change Table for customer)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM cdc.dbo_customer_CT

    UNION ALL

    -- 4. Check dbo.member_history (Temporal History Table for member)
    SELECT
        'dbo.member_history' AS object_name,
        COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.member_history

) AS results;
