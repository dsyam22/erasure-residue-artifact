SELECT object_name, rows_found FROM (
    -- 1. Check dbo.customer (Source Table/Current State)
    SELECT 'dbo.customer' AS object_name, COUNT(1) AS rows_found 
    FROM dbo.customer 
    WHERE customer_id = 42 OR full_name LIKE N'%Subject_0000042%'

    UNION ALL

    -- 2. Check dbo.member (System Versioned Temporal Table/Current State)
    SELECT 'dbo.member' AS object_name, COUNT(1) AS rows_found 
    FROM dbo.member 
    WHERE member_id = 42 OR full_name LIKE N'%Subject_0000042%'

    UNION ALL

    -- 3. Check dbo.member_history (Member History Table - High Persistence Risk)
    SELECT 'dbo.member_history' AS object_name, COUNT(1) AS rows_found 
    FROM dbo.member_history 
    WHERE member_id = 42 OR full_name LIKE N'%Subject_0000042%'

    UNION ALL

    -- 4. Check CDC table for dbo.customer (Change Tracking Log - Proof of Deletion Record)
    SELECT 'cdc.dbo_customer_CT' AS object_name, COUNT(1) AS rows_found 
    FROM cdc.dbo_customer_CT 
    WHERE customer_id = 42

) AS Results;
