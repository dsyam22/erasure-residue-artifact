DECLARE @target_customer_id INT = 42;
DECLARE @original_full_name NVARCHAR(100) = 'Subject_0000042';
DECLARE @original_email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @original_phone NVARCHAR(50) = '+1-555-0000042';

-- Check dbo.customer (Current table state)
SELECT 'dbo.customer' AS object_name, COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = @target_customer_id
  AND full_name = @original_full_name
  AND email = @original_email
  AND phone = @original_phone

UNION ALL

-- Check cdc.dbo_customer_CT (CDC capture table)
SELECT 'cdc.dbo_customer_CT' AS object_name, COUNT(*) AS rows_found
FROM cdc.dbo_customer_CT
WHERE customer_id = @target_customer_id
  AND full_name = @original_full_name
  AND email = @original_email
  AND phone = @original_phone

UNION ALL

-- Check dbo.member (Current system-versioned table state)
SELECT 'dbo.member' AS object_name, COUNT(*) AS rows_found
FROM dbo.member
WHERE member_id = @target_customer_id
  AND full_name = @original_full_name
  AND email = @original_email
  AND phone = @original_phone

UNION ALL

-- Check dbo.member_history (History table)
SELECT 'dbo.member_history' AS object_name, COUNT(*) AS rows_found
FROM dbo.member_history
WHERE member_id = @target_customer_id
  AND full_name = @original_full_name
  AND email = @original_email
  AND phone = @original_phone;
