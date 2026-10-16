WITH FoundData AS (
    SELECT
        'dbo.customer' AS object_name,
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.customer
)
SELECT object_name, rows_found FROM FoundData;
