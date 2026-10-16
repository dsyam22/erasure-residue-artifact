-- SCRIPT
DECLARE @subject_customer_id INT = 42;
DECLARE @subject_full_name NVARCHAR(200) = N'Subject_0000042';
DECLARE @subject_email NVARCHAR(400) = N'subject42@example.invalid';
DECLARE @subject_phone NVARCHAR(60) = N'+1-555-0000042';

SELECT 
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE 
    customer_id = @subject_customer_id
    OR full_name = @subject_full_name
    OR email = @subject_email
    OR phone = @subject_phone

UNION ALL

SELECT 
    'reporting.customer_replica' AS object_name,
    COUNT(*) AS rows_found
FROM reporting.customer_replica
WHERE 
    customer_id = @subject_customer_id
    OR full_name = @subject_full_name
    OR email = @subject_email
    OR phone = @subject_phone;
