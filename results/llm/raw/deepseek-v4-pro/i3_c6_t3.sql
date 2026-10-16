-- SCRIPT
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

SELECT 
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone

UNION ALL

SELECT 
    'dbo.member' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.member
WHERE member_id = 42
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone

UNION ALL

SELECT 
    'dbo.dbo_customer_CT' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.dbo_customer_CT
WHERE full_name = @full_name
   OR email = @email
   OR phone = @phone

UNION ALL

SELECT 
    'dbo.member_history' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.member_history
WHERE full_name = @full_name
   OR email = @email
   OR phone = @phone

UNION ALL

SELECT 
    'dbo.captured_columns' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.captured_columns
WHERE masking_function = @full_name
   OR masking_function = @email
   OR masking_function = @phone

UNION ALL

SELECT 
    'dbo.ddl_history' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.ddl_history
WHERE ddl_command LIKE N'%' + @full_name + N'%'
   OR ddl_command LIKE N'%' + @email + N'%'
   OR ddl_command LIKE N'%' + @phone + N'%';
