-- SCRIPT
SELECT 
    'dbo.customer' AS object_name,
    SUM(CASE 
        WHEN full_name = 'Subject_0000042' 
          OR email = 'subject42@example.invalid' 
        THEN 1 ELSE 0 END) AS rows_found
FROM dbo.customer

UNION ALL

SELECT 
    'dbo.systranschemas' AS object_name,
    0 AS rows_found;
