SELECT
    N'dbo.customer' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM [llm_i5].[dbo].[customer]
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

-- Query history directly: temporal queries can omit expired history
-- awaiting physical cleanup, as well as zero-duration versions.
SELECT
    N'dbo.customer_history' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM [llm_i5].[dbo].[customer_history]
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
