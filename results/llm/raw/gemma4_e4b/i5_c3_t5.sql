SELECT 
    'dbo.customer' AS object_name, 
    COUNT(CASE WHEN T1.customer_id = 42 AND T1.full_name = 'Subject_0000042' THEN 1 END) AS rows_found
FROM 
    dbo.customer T1

UNION ALL

SELECT 
    'dbo.customer_history' AS object_name, 
    COUNT(CASE WHEN T2.customer_id = 42 AND T2.full_name = 'Subject_0000042' THEN 1 END) AS rows_found
FROM 
    dbo.customer_history T2;
