WITH CheckResults AS (
    -- 1. Check the primary table for residual data (Should be empty due to column drop)
    SELECT
        'dbo.customer' AS object_name,
        ISNULL(
            (
                SELECT COUNT(CASE WHEN phone = '+1-555-0000042' THEN 1 END)
                FROM dbo.customer WITH (Nolock)
                WHERE customer_id = 42
            ), 0
        ) AS rows_found

    UNION ALL

    -- 2. Check the CDC Change Tracking table for residual data
    SELECT
        'cdc.dbo_customer_CT',
        ISNULL(
            (
                SELECT COUNT(CASE WHEN phone = '+1-555-0000042' THEN 1 END)
                FROM cdc.dbo_customer_CT WITH (Nolock)
                WHERE customer_id = 42
            ), 0
        )
)
SELECT object_name, rows_found FROM CheckResults;
