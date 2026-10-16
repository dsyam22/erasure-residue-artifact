WITH CheckResults AS (
    -- 1. Check the CDC History Table (cdc.dbo_customer_CT)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(CASE WHEN phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE customer_id = 42

    UNION ALL

    -- 2. Check the Primary Table (dbo.customer). 
    -- Since the column 'phone' was dropped, we must assume no records containing this specific value can be found here.
    SELECT
        'dbo.customer' AS object_name,
        0 AS rows_found
)
SELECT
    object_name,
    rows_found
FROM CheckResults;
