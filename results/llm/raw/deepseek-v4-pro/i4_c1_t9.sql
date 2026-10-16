DECLARE @results TABLE (object_name nvarchar(255), rows_found int);

INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
  AND (full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042');

INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = 42
  AND (full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042');

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
