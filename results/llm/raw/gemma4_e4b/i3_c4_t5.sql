DECLARE @TargetName NVARCHAR(100) = 'Subject_0000042';
DECLARE @TargetEmail NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @TargetPhone NVARCHAR(50) = '+1-555-0000042';

-- Check dbo.customer for residual PII data
SELECT
    CAST('dbo.customer' AS NVARCHAR(128)) AS object_name,
    COUNT(*) AS rows_found
FROM
    dbo.customer
WHERE
    full_name = @TargetName OR email = @TargetEmail OR phone = @TargetPhone

UNION ALL

-- Check dbo.member for residual PII data
SELECT
    CAST('dbo.member' AS NVARCHAR(128)) AS object_name,
    COUNT(*) AS rows_found
FROM
    dbo.member
WHERE
    full_name = @TargetName OR email = @TargetEmail OR phone = @TargetPhone;
