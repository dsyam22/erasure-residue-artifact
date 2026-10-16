-- SCRIPT
-- Check current rows, retained temporal history, and all CDC change rows.
-- Match any original identifier or personal-data value, not only complete records.
SELECT N'dbo.customer' AS object_name, COUNT_BIG(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT N'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE member_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT N'dbo.member_history', COUNT_BIG(*)
FROM dbo.member_history
WHERE member_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT N'cdc.dbo_customer_CT', COUNT_BIG(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
ORDER BY object_name;
