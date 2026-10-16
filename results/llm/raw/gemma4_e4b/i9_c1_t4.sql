WITH CheckResult AS (
    -- Counting records that match the subject's original personal data in the specified table.
    SELECT COUNT(1) AS FoundCount
    FROM dbo.customer
    WHERE customer_id = 42
      AND full_name = 'Subject_0000042'
      AND email = 'subject42@example.invalid'
      AND phone = '+1-555-0000042'
)
-- Formatting the output to match the required schema (object_name, rows_found).
SELECT
    'dbo.customer' AS object_name,
    CAST(T1.FoundCount AS INT) AS rows_found
FROM CheckResult T1;
