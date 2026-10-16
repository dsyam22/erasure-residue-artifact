WITH CheckResults AS (
    -- 1. Check the primary table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(customer_id) AS rows_found
    FROM dbo.customer
    WHERE customer_id = 42
      AND full_name = 'Subject_0000042'
      AND email = 'subject42@example.invalid'
      AND phone = '+1-555-0000042'

    UNION ALL

    -- 2. Check the CDC change table (cdc.dbo_customer_CT)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(customer_id) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE customer_id = 42
      AND full_name = 'Subject_0000042'
      AND email = 'subject42@example.invalid'
      AND phone = '+1-555-0000042'

    -- Note: Since the prompt only provided dbo.customer and its CDC table, 
    -- no checks for temporal history or other downstream tables are included.
)
SELECT object_name, rows_found FROM CheckResults;
