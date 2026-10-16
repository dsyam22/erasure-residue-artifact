WITH CustomerCheck AS (
    SELECT 
        N'dbo.customer' AS object_name, 
        CAST(COUNT(1) AS INT) AS rows_found
    FROM 
        dbo.customer
    WHERE 
        full_name = N'Subject_0000042' 
        AND email = N'subject42@example.invalid' 
        AND phone = N'+1-555-0000042'
),
MemberCheck AS (
    SELECT 
        N'dbo.member' AS object_name, 
        CAST(COUNT(1) AS INT) AS rows_found
    FROM 
        dbo.member
    WHERE 
        full_name = N'Subject_0000042' 
        AND email = N'subject42@example.invalid' 
        AND phone = N'+1-555-0000042'
)
SELECT 
    object_name, 
    rows_found 
FROM 
    CustomerCheck

UNION ALL

SELECT 
    object_name, 
    rows_found 
FROM 
    MemberCheck;
