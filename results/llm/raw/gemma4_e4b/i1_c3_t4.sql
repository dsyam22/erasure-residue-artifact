WITH ObjectChecks AS (
    -- Check 1: The primary source table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        (SELECT COUNT(1) FROM dbo.customer WHERE customer_id = 42) AS rows_found
    UNION ALL
    -- Check 2: CDC Change Table (cdc.dbo_customer_CT) - Data persists here until retention expires
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        (SELECT COUNT(1) FROM cdc.dbo_customer_CT WHERE customer_id = 42) AS rows_found
)
SELECT
    object_name,
    rows_found
FROM
    ObjectChecks;
