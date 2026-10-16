SELECT 
    'dbo.customer' AS object_name, 
    (SELECT COUNT(*) 
     FROM dbo.customer 
     WHERE customer_id = 42 
        OR full_name = 'Subject_0000042' 
        OR email = 'subject42@example.invalid' 
        OR phone = '+1-555-0000042'
    ) AS rows_found
UNION ALL
SELECT 
    'dbo.customer_history' AS object_name, 
    (SELECT COUNT(*) 
     FROM dbo.customer_history 
     WHERE customer_id = 42 
        OR full_name = 'Subject_0000042' 
        OR email = 'subject42@example.invalid' 
        OR phone = '+1-555-0000042'
    ) AS rows_found;
