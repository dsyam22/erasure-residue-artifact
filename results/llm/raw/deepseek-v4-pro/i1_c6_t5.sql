-- SCRIPT
DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = 'Subject_0000042';
DECLARE @email nvarchar(255) = 'subject42@example.invalid';
DECLARE @phone nvarchar(255) = '+1-555-0000042';

SELECT 
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone

UNION ALL

SELECT 
    'cdc.dbo_customer_CT' AS object_name,
    COUNT(*) AS rows_found
FROM cdc.dbo_customer_CT
WHERE full_name = @full_name
   OR email = @email
   OR phone = @phone

UNION ALL

SELECT 
    'cdc.captured_columns' AS object_name,
    COUNT(*) AS rows_found
FROM cdc.captured_columns
WHERE masking_function IN (@full_name, @email, @phone)

UNION ALL

SELECT 
    'cdc.ddl_history' AS object_name,
    COUNT(*) AS rows_found
FROM cdc.ddl_history
WHERE ddl_command LIKE '%' + @full_name + '%'
   OR ddl_command LIKE '%' + @email + '%'
   OR ddl_command LIKE '%' + @phone + '%';
