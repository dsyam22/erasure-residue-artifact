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
    CROSS JOIN subject_data s
    WHERE c.customer_id = s.customer_id
       OR c.full_name = s.full_name
       OR c.email = s.email
       OR c.phone = s.phone
)
SELECT object_name, rows_found
FROM checks;
