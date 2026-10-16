DECLARE @original_full_name nvarchar(200) = N'Subject_0000042';
DECLARE @original_email nvarchar(400) = N'subject42@example.invalid';
DECLARE @original_phone nvarchar(60) = N'+1-555-0000042';
DECLARE @customer_id int = 42;
DECLARE @member_id int = 42;

SELECT 
    N'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = @customer_id
  AND (
      full_name = @original_full_name
      OR email = @original_email
      OR phone = @original_phone
  )

UNION ALL

SELECT 
    N'dbo.member' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.member
WHERE member_id = @member_id
  AND (
      full_name = @original_full_name
      OR email = @original_email
      OR phone = @original_phone
  )

UNION ALL

SELECT 
    N'dbo.member_history' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.member_history
WHERE member_id = @member_id
  AND (
      full_name = @original_full_name
      OR email = @original_email
      OR phone = @original_phone
  );
