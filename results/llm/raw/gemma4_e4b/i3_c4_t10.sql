DECLARE @SubjectName NVARCHAR(200) = 'Subject_0000042';
DECLARE @SubjectEmail NVARCHAR(400) = 'subject42@example.invalid';
DECLARE @SubjectPhone NVARCHAR(60) = '+1-555-0000042';

-- Check dbo.customer
SELECT 
    'dbo.customer' AS object_name, 
    COUNT(T1.customer_id) AS rows_found
FROM 
    dbo.customer T1
WHERE 
    T1.full_name = @SubjectName OR 
    T1.email = @SubjectEmail OR 
    T1.phone = @SubjectPhone

UNION ALL

-- Check dbo.member
SELECT 
    'dbo.member' AS object_name, 
    COUNT(T2.member_id) AS rows_found
FROM 
    dbo.member T2
WHERE 
    T2.full_name = @SubjectName OR 
    T2.email = @SubjectEmail OR 
    T2.phone = @SubjectPhone

UNION ALL

-- Check dbo.member_history (The most likely location for orphaned data)
SELECT 
    'dbo.member_history' AS object_name, 
    COUNT(T3.member_id) AS rows_found
FROM 
    dbo.member_history T3
WHERE 
    T3.full_name = @SubjectName OR 
    T3.email = @SubjectEmail OR 
    T3.phone = @SubjectPhone

-- Since the requirement mandates listing every object checked, even if no data is found (0 rows), we must ensure all three tables are listed.
-- The UNION ALL structure above only lists objects where a match occurs. We use an explicit SELECT to guarantee the required output format for zero matches.
SELECT 
    'dbo.customer' AS object_name, 
    ISNULL((SELECT COUNT(T1.customer_id) FROM dbo.customer T1 WHERE T1.full_name = @SubjectName OR T1.email = @SubjectEmail OR T1.phone = @SubjectPhone), 0) AS rows_found

UNION ALL

SELECT 
    'dbo.member' AS object_name, 
    ISNULL((SELECT COUNT(T2.member_id) FROM dbo.member T2 WHERE T2.full_name = @SubjectName OR T2.email = @SubjectEmail OR T2.phone = @SubjectPhone), 0) AS rows_found

UNION ALL

SELECT 
    'dbo.member_history' AS object_name, 
    ISNULL((SELECT COUNT(T3.member_id) FROM dbo.member_history T3 WHERE T3.full_name = @SubjectName OR T3.email = @SubjectEmail OR T3.phone = @SubjectPhone), 0) AS rows_found;
