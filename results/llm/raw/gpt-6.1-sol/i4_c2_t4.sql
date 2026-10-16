USE [llm_i4];

-- Check current rows, temporal history, and retained CDC change rows.
-- Retained numeric identifiers alone do not indicate that the anonymized
-- name, email, or phone values are still present.
SELECT
    N'dbo.customer' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM dbo.customer
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT
    N'dbo.member',
    COUNT_BIG(*)
FROM dbo.member
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT
    N'dbo.member_history',
    COUNT_BIG(*)
FROM dbo.member_history
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT
    N'cdc.dbo_customer_CT',
    COUNT_BIG(*)
FROM cdc.dbo_customer_CT
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
