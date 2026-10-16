WITH subject_data AS (
    SELECT 
        42 AS customer_id,
        N'Subject_0000042' AS full_name,
        N'subject42@example.invalid' AS email,
        N'+1-555-0000042' AS phone
),
checks AS (
    SELECT 
        'dbo.customer' AS object_name,
        COUNT(*) AS rows_found
    FROM dbo.customer c
    INNER JOIN subject_data s
        ON c.customer_id = s.customer_id
        AND c.full_name = s.full_name
        AND c.email = s.email
        AND c.phone = s.phone

    UNION ALL

    SELECT 
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(*) AS rows_found
    FROM cdc.dbo_customer_CT ct
    INNER JOIN subject_data s
        ON ct.customer_id = s.customer_id
        AND ct.full_name = s.full_name
        AND ct.email = s.email
        AND ct.phone = s.phone
)
SELECT object_name, rows_found
FROM checks
ORDER BY object_name;
