-- SCRIPT
-- Check current rows, raw CDC rows (including update before-images),
-- and the temporal history table directly, including zero-duration versions.
-- Match any original personal-data value; an identifier alone is not a match.
SELECT N'dbo.customer' AS object_name, COUNT_BIG(*) AS rows_found
FROM [llm_i4].[dbo].[customer]
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT N'dbo.member', COUNT_BIG(*)
FROM [llm_i4].[dbo].[member]
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT N'dbo.member_history', COUNT_BIG(*)
FROM [llm_i4].[dbo].[member_history]
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT N'cdc.dbo_customer_CT', COUNT_BIG(*)
FROM [llm_i4].[cdc].[dbo_customer_CT]
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
ORDER BY object_name;
