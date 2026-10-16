DECLARE @TargetName NVARCHAR(256) = 'Subject_0000042';
DECLARE @TargetEmail NVARCHAR(256) = 'subject42@example.invalid';
DECLARE @TargetPhone NVARCHAR(50) = '+1-555-0000042';

-- Variables to hold the count for each table
DECLARE @CustomerCount INT;
DECLARE @MemberCount INT;

-- 1. Check dbo.customer
SELECT @CustomerCount = COUNT(*)
FROM dbo.customer c
WHERE c.full_name = @TargetName
  AND c.email = @TargetEmail
  AND c.phone = @TargetPhone;

-- 2. Check dbo.member
SELECT @MemberCount = COUNT(*)
FROM dbo.member m
WHERE m.full_name = @TargetName
  AND m.email = @TargetEmail
  AND m.phone = @TargetPhone;

-- Return the results in the required single result set format
SELECT 
    'dbo.customer' AS object_name, 
    @CustomerCount AS rows_found
UNION ALL
SELECT 
    'dbo.member' AS object_name, 
    @MemberCount AS rows_found;
