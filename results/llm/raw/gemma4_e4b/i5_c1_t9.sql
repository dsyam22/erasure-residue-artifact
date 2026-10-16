WITH ObjectChecks AS (
    -- Check 1: dbo.customer table
    SELECT 
        'dbo.customer' AS object_name,
        (SELECT COUNT(*) FROM dbo.customer WHERE customer_id = 42) AS rows_found
),
FinalResults AS (
    SELECT
        object_name,
        COALESCE(rows_found, 0) AS rows_found
    FROM ObjectChecks
)
-- The final SELECT ensures only the required result set is returned.
SELECT object_name, rows_found FROM FinalResults;
