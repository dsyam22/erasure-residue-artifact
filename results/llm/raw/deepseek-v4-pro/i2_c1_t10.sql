WITH subject_data AS (
    SELECT
        42 AS customer_id,
        N'Subject_0000042' AS full_name,
        N'subject42@example.invalid' AS email,
        N'+1-555-0000042' AS phone
)
SELECT
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer AS c
INNER JOIN subject_data AS s
    ON c.customer_id = s.customer_id
    AND c.full_name = s.full_name
    AND c.email = s.email
    AND c.phone = s.phone;
