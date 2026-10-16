-- SCRIPT
-- Checks live customer rows and all retained CDC row images, including
-- deletes and both update images, without restricting the CDC LSN range.
-- This checks queryable row data, not backups, transaction-log contents,
-- or deallocated data pages.
SELECT N'dbo.customer' AS object_name,
       COUNT_BIG(*) AS rows_found
FROM [llm_i1].[dbo].[customer]
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'

UNION ALL

SELECT N'cdc.dbo_customer_CT' AS object_name,
       COUNT_BIG(*) AS rows_found
FROM [llm_i1].[cdc].[dbo_customer_CT]
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
