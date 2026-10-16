WITH CheckResults AS (
    -- 1. Check the primary customer table itself
    SELECT
        'dbo.customer' AS object_name,
        COUNT(CASE WHEN c.customer_id = 42 AND c.full_name LIKE '%Subject_0000042%' AND c.email LIKE '%subject42@example.invalid%' AND c.phone LIKE '%+1-555-0000042%' THEN 1 END) AS count_matches
    FROM
        dbo.customer c
),
ObjectSummary AS (
    SELECT
        object_name,
        MAX(count_matches) AS rows_found
    FROM
        CheckResults
    GROUP BY
        object_name
)
-- Select the final mandated format result set. If no checks were performed on other tables (due to lack of information), only dbo.customer will be listed.
SELECT 
    T1.object_name, 
    ISNULL(T1.rows_found, 0) AS rows_found
FROM (VALUES ('dbo.customer')) AS T_Objects(object_name) -- Ensures at least the main object is checked and reported
LEFT JOIN ObjectSummary ON T_Objects.object_name = ObjectSummary.object_name;
