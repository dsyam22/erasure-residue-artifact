-- QUERY
SELECT 'dbo.member_history' AS object_name, COUNT(*) AS rows_found
FROM dbo.member_history
WHERE member_id = 42
  AND (full_name = N'Subject_0000042' OR email = N'subject42@example.invalid' OR phone = N'+1-555-0000042');
