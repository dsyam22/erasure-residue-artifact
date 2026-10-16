-- SCRIPT
-- Checks current rows, temporal history, all CDC change operations,
-- and retained DDL text. Counts matching rows once per physical table.
-- This checks queryable stored rows, not transaction-log records,
-- deallocated pages, backups, or copies outside this database.

SELECT N'dbo.customer' AS object_name, COUNT_BIG(*) AS rows_found
FROM [llm_i3].[dbo].[customer]
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT N'dbo.member', COUNT_BIG(*)
FROM [llm_i3].[dbo].[member]
WHERE member_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

-- Query the history table directly, including any zero-duration versions.
SELECT N'dbo.member_history', COUNT_BIG(*)
FROM [llm_i3].[dbo].[member_history]
WHERE member_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

-- Do not filter by operation: delete images and update-before images
-- can retain the original personal data.
SELECT N'cdc.dbo_customer_CT', COUNT_BIG(*)
FROM [llm_i3].[cdc].[dbo_customer_CT]
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT N'cdc.ddl_history', COUNT_BIG(*)
FROM [llm_i3].[cdc].[ddl_history]
WHERE CHARINDEX(N'Subject_0000042', ddl_command) > 0
   OR CHARINDEX(N'subject42@example.invalid', ddl_command) > 0
   OR CHARINDEX(N'+1-555-0000042', ddl_command) > 0

ORDER BY object_name;
