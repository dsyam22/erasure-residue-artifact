SELECT 
    'dbo.customer' AS object_name, 
    COUNT(CASE WHEN T1.full_name = N'Subject_0000042' OR T1.email = N'subject42@example.invalid' OR T1.phone = N'+1-555-0000042' THEN 1 END) AS rows_found
FROM dbo.customer AS T1

UNION ALL

SELECT 
    'dbo.member', 
    COUNT(CASE WHEN T2.full_name = N'Subject_0000042' OR T2.email = N'subject42@example.invalid' OR T2.phone = N'+1-555-0000042' THEN 1 END)
FROM dbo.member AS T2;
