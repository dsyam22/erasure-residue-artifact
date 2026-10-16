SELECT
    'dbo.customer' AS object_name,
    COUNT(CASE WHEN T1.full_name = 'Subject_0000042' OR 
                        T1.email LIKE '%subject42@example.invalid%' OR 
                        T1.phone LIKE '%+1-555-0000042%' THEN 1 END) AS rows_found
FROM
    dbo.customer T1;
