SELECT 
    CAST('dbo.customer' AS VARCHAR(128)) AS object_name,
    COUNT(CASE WHEN T1.full_name = N'Subject_0000042' AND T1.email = N'subject42@example.invalid' AND T1.phone = N'+1-555-0000042' THEN 1 END) AS rows_found
FROM 
    dbo.customer AS T1;
