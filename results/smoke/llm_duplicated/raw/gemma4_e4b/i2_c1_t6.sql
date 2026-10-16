WITH CheckResults AS (
    SELECT 
        COUNT(T.customer_id) AS rows_found
    FROM dbo.customer T
    WHERE T.customer_id = 42
       OR T.full_name = 'Subject_0000042'
       OR T.email = 'subject42@example.invalid'
       OR T.phone = '+1-555-0000042'
)
SELECT 
    'dbo.customer' AS object_name,
    CR.rows_found
FROM CheckResults CR;
