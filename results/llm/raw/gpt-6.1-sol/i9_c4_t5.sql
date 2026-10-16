USE [llm_i9];

-- Checks current rows and the physical temporal history table separately.
-- Direct history access also includes zero-duration versions.
-- Counts rows matching any original identifier or personal-data value.
-- This logical check does not verify residual bytes in data/log files or backups.
SELECT
    N'dbo.customer' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT
    N'dbo.customer_history' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM dbo.customer_history
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
