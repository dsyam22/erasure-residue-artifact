-- QUERY
SELECT 
    'dbo.customer' AS object_name,
    SUM(CASE 
        WHEN full_name = 'Subject_0000042' 
          OR email = 'subject42@example.invalid' 
          OR phone = '+1-555-0000042' 
        THEN 1 ELSE 0 END) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
UNION ALL
SELECT 
    'dbo.member' AS object_name,
    SUM(CASE 
        WHEN full_name = 'Subject_0000042' 
          OR email = 'subject42@example.invalid' 
          OR phone = '+1-555-0000042' 
        THEN 1 ELSE 0 END) AS rows_found
FROM dbo.member
WHERE member_id = 42;
