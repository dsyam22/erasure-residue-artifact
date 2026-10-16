WITH CustomerCheck AS (
    SELECT 
        CAST('dbo.customer' AS NVARCHAR(120)) AS object_name,
        COUNT(CASE WHEN T1.full_name = 'Subject_0000042' OR 
                       T1.email = 'subject42@example.invalid' OR 
                       T1.phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.customer T1
),
MemberCheck AS (
    SELECT 
        CAST('dbo.member' AS NVARCHAR(120)) AS object_name,
        COUNT(CASE WHEN T2.full_name = 'Subject_0000042' OR 
                       T2.email = 'subject42@example.invalid' OR 
                       T2.phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.member T2
)
SELECT object_name, rows_found FROM CustomerCheck
UNION ALL
SELECT object_name, rows_found FROM MemberCheck;
