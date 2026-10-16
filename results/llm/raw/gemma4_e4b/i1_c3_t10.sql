WITH CheckResults AS (
    -- 1. Check the primary data table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        ISNULL(COUNT(T.customer_id), 0) AS rows_found
    FROM dbo.customer T
    WHERE T.customer_id = 42
      AND T.full_name = 'Subject_0000042'
      AND T.email = 'subject42@example.invalid'
      AND T.phone = '+1-555-0000042'

    UNION ALL

    -- 2. Check the Change Data Capture (CDC) table for residual data
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        ISNULL(COUNT(T.customer_id), 0) AS rows_found
    FROM cdc.dbo_customer_CT T
    WHERE T.customer_id = 42
      AND T.full_name = 'Subject_0000042'
      AND T.email = 'subject42@example.invalid'
      AND T.phone = '+1-555-0000042'

    UNION ALL

    -- 3. Check for any other potential copies (Placeholder/Safety check - if schema implied more tables)
    -- Since no other tables are provided, this section acts as a placeholder to ensure the structure is correct
    SELECT
        NULL AS object_name, -- Placeholder name since no third table was specified
        0 AS rows_found     -- Always 0 for non-existent checks
)
SELECT
    object_name,
    rows_found
FROM CheckResults;
