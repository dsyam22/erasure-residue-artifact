SET NOCOUNT ON;

SELECT 
    'dbo.customer' AS object_name, 
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042'

UNION ALL

SELECT 
    'dbo.member' AS object_name, 
    COUNT(*) AS rows_found
FROM dbo.member FOR SYSTEM_TIME ALL
WHERE full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';
