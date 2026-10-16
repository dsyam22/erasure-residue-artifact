WITH CheckResults AS (
    -- CDC History Table for dbo.customer
    SELECT 
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM cdc.dbo_customer_CT

    UNION ALL

    -- Current dbo.customer table (Should be zero after DELETE)
    SELECT 
        'dbo.customer',
        COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END)
    FROM dbo.customer

    UNION ALL

    -- Current dbo.member table (Should be zero after DELETE)
    SELECT 
        'dbo.member',
        COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END)
    FROM dbo.member

    UNION ALL

    -- Temporal History Table for dbo.member
    SELECT 
        'dbo.member_history',
        COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END)
    FROM dbo.member_history

    -- Note: While the prompt specified checking dbo_customer, we only have access to its CDC change table (cdc.dbo_customer_CT).
    -- We assume that if cdc.dbo_customer_CT is checked, it covers the required historical audit trail for customer data.
)
SELECT 
    object_name,
    rows_found
FROM CheckResults;
