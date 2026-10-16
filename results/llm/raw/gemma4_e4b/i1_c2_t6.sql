WITH ObjectChecks AS (
    -- 1. Check the primary operational table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = 42
      AND full_name = 'Subject_0000042'
      AND email = 'subject42@example.invalid'
      AND phone = '+1-555-0000042'

    UNION ALL

    -- 2. Check the CDC Change Table (cdc.dbo_customer_CT)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(*) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE customer_id = 42
      AND full_name = 'Subject_0000042'
      AND email = 'subject42@example.invalid'
      AND phone = '+1-555-0000042'
)
SELECT object_name, rows_found FROM ObjectChecks;
