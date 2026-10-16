SET NOCOUNT ON;
DECLARE @results TABLE (object_name NVARCHAR(255), rows_found INT);

INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*) 
FROM dbo.customer
WHERE customer_id = 42 
   OR full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';

IF OBJECT_ID('cdc.dbo_customer_CT') IS NOT NULL
BEGIN
    INSERT INTO @results (object_name, rows_found)
    EXEC('SELECT ''cdc.dbo_customer_CT'', COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id = 42 OR full_name = ''Subject_0000042'' OR email = ''subject42@example.invalid'' OR phone = ''+1-555-0000042''');
END

IF OBJECT_ID('dbo.dbo_customer_CT') IS NOT NULL
BEGIN
    INSERT INTO @results (object_name, rows_found)
    EXEC('SELECT ''dbo.dbo_customer_CT'', COUNT(*) FROM dbo.dbo_customer_CT WHERE customer_id = 42 OR full_name = ''Subject_0000042'' OR email = ''subject42@example.invalid'' OR phone = ''+1-555-0000042''');
END

SELECT object_name, rows_found 
FROM @results;
