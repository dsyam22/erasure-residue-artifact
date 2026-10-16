SELECT
    T1.object_name,
    T1.rows_found
FROM
(
    -- 1. Check the live source table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(CASE WHEN customer_id = 42 AND full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.customer

    UNION ALL

    -- 2. Check the Change Data Capture table (cdc.dbo_customer_CT)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(CASE WHEN customer_id = 42 AND full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END)
    FROM cdc.dbo_customer_CT

    -- Note: Based on the schema and context, no explicit downstream copies are provided, 
    -- so only the primary table and its CDC tracking mechanism are checked.

) AS T1;
