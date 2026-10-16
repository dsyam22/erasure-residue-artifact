WITH CustomerCheck AS (
    -- Count records in dbo.customer for ID 42 that still contain original PI
    SELECT 
        'dbo.customer' AS object_name, 
        COUNT(T1.*) AS rows_found
    FROM 
        dbo.customer T1
    WHERE 
        T1.customer_id = 42 
        AND (
            T1.full_name = 'Subject_0000042' OR 
            T1.email = 'subject42@example.invalid' OR 
            T1.phone = '+1-555-0000042'
        )
),
MemberCheck AS (
    -- Count records in dbo.member for ID 42 that still contain original PI
    SELECT 
        'dbo.member' AS object_name, 
        COUNT(T2.*) AS rows_found
    FROM 
        dbo.member T2
    WHERE 
        T2.member_id = 42 
        AND (
            T2.full_name = 'Subject_0000042' OR 
            T2.email = 'subject42@example.invalid' OR 
            T2.phone = '+1-555-0000042'
        )
)
-- Combine results into the required single result set format
SELECT object_name, rows_found FROM CustomerCheck
UNION ALL
SELECT object_name, rows_found FROM MemberCheck;
