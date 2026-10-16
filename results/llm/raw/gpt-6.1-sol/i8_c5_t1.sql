-- SCRIPT
-- Checks the only discovered user table for any original subject identifier.
-- This checks queryable rows, not physical erasure: deleted-row remnants,
-- transaction logs (access denied during inspection), and backups are not checked.
-- A zero count therefore does not establish that all stored copies are erased.

SELECT
    N'dbo.customer' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM [llm_i8].[dbo].[customer]
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
