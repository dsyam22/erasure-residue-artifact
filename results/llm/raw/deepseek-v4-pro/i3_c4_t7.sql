SELECT 'dbo.customer' AS object_name, COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT 'dbo.member_history', COUNT(*)
FROM dbo.member_history
WHERE member_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT 'cdc.fn_cdc_get_all_changes_dbo_customer', COUNT(*)
FROM cdc.fn_cdc_get_all_changes_dbo_customer(NULL, NULL)
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT 'cdc.fn_cdc_get_net_changes_dbo_customer', COUNT(*)
FROM cdc.fn_cdc_get_net_changes_dbo_customer(NULL, NULL)
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
