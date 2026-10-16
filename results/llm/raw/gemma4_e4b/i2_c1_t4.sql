SELECT 
    CAST('dbo.customer' AS NVARCHAR(256)) AS object_name, 
    COUNT(T1.customer_id) AS rows_found
FROM 
    dbo.customer AS T1
WHERE 
    T1.full_name = 'Subject_0000042' OR 
    T1.email = 'subject42@example.invalid' OR 
    T1.phone = '+1-555-0000042';
