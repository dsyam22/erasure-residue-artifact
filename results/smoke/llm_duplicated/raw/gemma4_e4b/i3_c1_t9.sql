DECLARE @target_full_name NVARCHAR(256) = 'Subject_0000042';
DECLARE @target_email NVARCHAR(256) = 'subject42@example.invalid';
DECLARE @target_phone NVARCHAR(50) = '+1-555-0000042';

-- Check dbo.customer for residual data
SELECT 
    'dbo.customer' AS object_name, 
    COUNT(*) AS rows_found
FROM 
    dbo.customer
WHERE 
    full_name = @target_full_name 
    AND email = @target_email 
    AND phone = @target_phone

UNION ALL

-- Check dbo.member for residual data
SELECT 
    'dbo.member' AS object_name, 
    COUNT(*) AS rows_found
FROM 
    dbo.member
WHERE 
    full_name = @target_full_name 
    AND email = @target_email 
    AND phone = @target_phone;
