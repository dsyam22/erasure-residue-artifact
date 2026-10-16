WITH ObjectsToCheck AS (
    -- List all objects identified in the schema inspection that might contain PII
    SELECT 'dbo.customer' AS object_name, 1 AS check_order -- Placeholder for structured checking
),
Results AS (
    SELECT
        T1.object_name,
        CASE
            -- Check if all specific identifiers are present and match the subject data in this table
            WHEN EXISTS (
                SELECT 1
                FROM dbo.customer c
                WHERE c.customer_id = 42
                  AND c.full_name = 'Subject_0000042'
                  AND c.email = 'subject42@example.invalid'
                  AND c.phone = '+1-555-0000042'
            ) THEN 1
            ELSE 0
        END AS rows_found
    FROM ObjectsToCheck T1
)
-- Select the final required structure, ensuring only one result set is returned.
SELECT 
    object_name,
    rows_found
FROM Results;
