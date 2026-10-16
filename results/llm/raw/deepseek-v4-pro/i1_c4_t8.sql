SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(400) = N'subject42@example.invalid';
DECLARE @phone nvarchar(60) = N'+1-555-0000042';

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
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone

UNION ALL

SELECT 
    'cdc.captured_columns' AS object_name,
    COUNT(*) AS rows_found
FROM cdc.captured_columns
WHERE column_name IN (N'full_name', N'email', N'phone', N'customer_id')
  AND (CAST(column_name AS nvarchar(200)) = @full_name
       OR CAST(column_name AS nvarchar(400)) = @email
       OR CAST(column_name AS nvarchar(60)) = @phone
       OR CAST(column_name AS nvarchar(10)) = CAST(@customer_id AS nvarchar(10)))

UNION ALL

SELECT 
    'cdc.change_tables' AS object_name,
    COUNT(*) AS rows_found
FROM cdc.change_tables
WHERE capture_instance = N'dbo_customer_CT'
  AND (CAST(capture_instance AS nvarchar(200)) = @full_name
       OR CAST(capture_instance AS nvarchar(400)) = @email
       OR CAST(capture_instance AS nvarchar(60)) = @phone
       OR CAST(capture_instance AS nvarchar(10)) = CAST(@customer_id AS nvarchar(10)))

UNION ALL

SELECT 
    'cdc.ddl_history' AS object_name,
    COUNT(*) AS rows_found
FROM cdc.ddl_history
WHERE CAST(ddl_command AS nvarchar(max)) LIKE N'%Subject_0000042%'
   OR CAST(ddl_command AS nvarchar(max)) LIKE N'%subject42@example.invalid%'
   OR CAST(ddl_command AS nvarchar(max)) LIKE N'%+1-555-0000042%'
   OR CAST(ddl_command AS nvarchar(max)) LIKE N'%42%'

UNION ALL

SELECT 
    'cdc.index_columns' AS object_name,
    COUNT(*) AS rows_found
FROM cdc.index_columns
WHERE column_name IN (N'full_name', N'email', N'phone', N'customer_id')
  AND (column_name = @full_name
       OR column_name = @email
       OR column_name = @phone
       OR column_name = CAST(@customer_id AS sysname))

UNION ALL

SELECT 
    'cdc.lsn_time_mapping' AS object_name,
    COUNT(*) AS rows_found
FROM cdc.lsn_time_mapping
WHERE 1 = 0

UNION ALL

SELECT 
    'dbo.systranschemas' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.systranschemas
WHERE 1 = 0;
