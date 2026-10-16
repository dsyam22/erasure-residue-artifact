-- SCRIPT
SELECT 
    'dbo.customer' AS object_name,
    SUM(CASE 
        WHEN full_name = 'Subject_0000042' 
          OR email = 'subject42@example.invalid' 
          OR phone = '+1-555-0000042' 
        THEN 1 ELSE 0 END) AS rows_found
FROM dbo.customer
UNION ALL
SELECT 
    'dbo.customer_history' AS object_name,
    SUM(CASE 
        WHEN full_name = 'Subject_0000042' 
          OR email = 'subject42@example.invalid' 
          OR phone = '+1-555-0000042' 
        THEN 1 ELSE 0 END) AS rows_found
FROM dbo.customer_history;
