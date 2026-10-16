-- SCRIPT
USE [llm_i4];

SELECT N'dbo.customer' AS object_name, COUNT_BIG(*) AS rows_found
FROM dbo.customer
WHERE full_name IN (N'Subject_0000042', N'subject42@example.invalid', N'+1-555-0000042')
   OR email     IN (N'Subject_0000042', N'subject42@example.invalid', N'+1-555-0000042')
   OR phone     IN (N'Subject_0000042', N'subject42@example.invalid', N'+1-555-0000042')

UNION ALL

SELECT N'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE full_name IN (N'Subject_0000042', N'subject42@example.invalid', N'+1-555-0000042')
   OR email     IN (N'Subject_0000042', N'subject42@example.invalid', N'+1-555-0000042')
   OR phone     IN (N'Subject_0000042', N'subject42@example.invalid', N'+1-555-0000042')

UNION ALL

SELECT N'dbo.member_history', COUNT_BIG(*)
FROM dbo.member_history
WHERE full_name IN (N'Subject_0000042', N'subject42@example.invalid', N'+1-555-0000042')
   OR email     IN (N'Subject_0000042', N'subject42@example.invalid', N'+1-555-0000042')
   OR phone     IN (N'Subject_0000042', N'subject42@example.invalid', N'+1-555-0000042');
