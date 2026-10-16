WITH ObjectChecks AS (
    -- Check 1: Primary Table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(CASE WHEN customer_id = 42 AND full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS BIGINT) AS rows_found
    FROM dbo.customer

    UNION ALL

    -- Check 2: Replica Table (reporting.customer_replica)
    SELECT
        'reporting.customer_replica' AS object_name,
        CAST(COUNT(CASE WHEN customer_id = 42 AND full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS BIGINT)
    FROM reporting.customer_replica

    -- Note: Since cdc_enabled=0 and both tables are NON_TEMPORAL, no CDC or history checks are necessary.
)
SELECT object_name, rows_found
FROM ObjectChecks;
