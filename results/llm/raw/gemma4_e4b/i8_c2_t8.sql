WITH CheckResults AS (
    SELECT
        'dbo.customer' AS object_name,
        COUNT(CASE 
            WHEN c.customer_id = 42 
                OR c.full_name = 'Subject_0000042' 
                OR c.email = 'subject42@example.invalid' 
                OR c.phone = '+1-555-0000042' 
            THEN 1 
        END) AS rows_found
    FROM dbo.customer c
)
SELECT object_name, rows_found FROM CheckResults;
