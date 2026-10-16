WITH CheckResults AS (
    -- 1. Check the active table (dbo.customer)
    SELECT 'dbo.customer' AS object_name, COUNT(1) AS rows_found
    FROM dbo.customer
    WHERE customer_id = 42
      AND full_name = N'Subject_0000042'
      AND email = N'subject42@example.invalid'

    UNION ALL

    -- 2. Check the temporal history table (dbo.customer_history)
    SELECT 'dbo.customer_history' AS object_name, COUNT(1) AS rows_found
    FROM dbo.customer_history
    WHERE customer_id = 42
      AND full_name = N'Subject_0000042'
      AND email = N'subject42@example.invalid'

    -- Note: Based on the provided schema and configuration (no CDC enabled, no other copies),
    -- these two locations cover all potential persistence points of this personal data.
)
SELECT object_name, rows_found FROM CheckResults;
