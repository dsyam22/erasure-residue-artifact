WITH ObjectChecks AS (
    -- Check 1: The primary operational table (dbo.customer)
    SELECT
        CAST('dbo.customer' AS NVARCHAR(256)) AS object_name,
        COUNT(CASE WHEN T1.customer_id = 42 AND T1.full_name = 'Subject_0000042' THEN 1 END) AS rows_found
    FROM dbo.customer AS T1

    UNION ALL

    -- Check 2: The system-versioned history table (dbo.customer_history)
    SELECT
        CAST('dbo.customer_history' AS NVARCHAR(256)) AS object_name,
        COUNT(CASE WHEN T2.customer_id = 42 AND T2.full_name = 'Subject_0000042' THEN 1 END) AS rows_found
    FROM dbo.customer_history AS T2
)
SELECT
    object_name,
    rows_found
FROM ObjectChecks;
