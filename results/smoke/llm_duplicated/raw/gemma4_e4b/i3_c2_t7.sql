WITH Results AS (
    -- 1. Check dbo.customer (Primary Table)
    SELECT 
        'dbo.customer' AS object_name, 
        CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS INT) AS rows_found
    FROM dbo.customer

    UNION ALL

    -- 2. Check dbo.member (Primary Table - even though deleted, checking for residual records is vital)
    SELECT 
        'dbo.member' AS object_name, 
        CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS INT)

    UNION ALL

    -- 3. Check dbo.member_history (System-Versioned History Table - Highest Priority)
    SELECT 
        'dbo.member_history' AS object_name, 
        CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS INT)

    UNION ALL
    
    -- 4. Check cdc.dbo_customer_CT (CDC Change Table Metadata - Checking for the ID associated with the deleted record)
    -- Note: Since we don't know the exact structure of data columns in this CT table, we check if the subject ID was recorded as being processed/changed.
    SELECT 
        'cdc.dbo_customer_CT' AS object_name, 
        CAST(ISNULL((SELECT COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id = 42), 0) AS INT)

)
SELECT * FROM Results;
