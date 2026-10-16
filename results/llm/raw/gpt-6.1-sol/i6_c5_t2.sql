-- SCRIPT
-- Check the original phone value only; retained names and emails are not
-- themselves evidence of failed erasure. Include every CDC operation,
-- including historical delete and update-before images.
-- This checks accessible table data, not backups or deallocated storage.
SELECT N'dbo.customer' AS object_name, COUNT_BIG(*) AS rows_found
FROM [llm_i6].[dbo].[customer]
WHERE CHARINDEX(N'+1-555-0000042', full_name) > 0
   OR CHARINDEX(N'+1-555-0000042', email) > 0

UNION ALL

SELECT N'cdc.dbo_customer_CT', COUNT_BIG(*)
FROM [llm_i6].[cdc].[dbo_customer_CT]
WHERE CHARINDEX(N'+1-555-0000042', phone) > 0
   OR CHARINDEX(N'+1-555-0000042', full_name) > 0
   OR CHARINDEX(N'+1-555-0000042', email) > 0

UNION ALL

SELECT N'cdc.ddl_history', COUNT_BIG(*)
FROM [llm_i6].[cdc].[ddl_history]
WHERE CHARINDEX(N'+1-555-0000042', ddl_command) > 0

UNION ALL

SELECT N'cdc.captured_columns', COUNT_BIG(*)
FROM [llm_i6].[cdc].[captured_columns]
WHERE CHARINDEX(N'+1-555-0000042', column_name) > 0
   OR CHARINDEX(N'+1-555-0000042', column_type) > 0
   OR CHARINDEX(N'+1-555-0000042', masking_function) > 0

UNION ALL

SELECT N'cdc.change_tables', COUNT_BIG(*)
FROM [llm_i6].[cdc].[change_tables]
WHERE CHARINDEX(N'+1-555-0000042', capture_instance) > 0
   OR CHARINDEX(N'+1-555-0000042', role_name) > 0
   OR CHARINDEX(N'+1-555-0000042', index_name) > 0
   OR CHARINDEX(N'+1-555-0000042', filegroup_name) > 0

UNION ALL

SELECT N'cdc.index_columns', COUNT_BIG(*)
FROM [llm_i6].[cdc].[index_columns]
WHERE CHARINDEX(N'+1-555-0000042', column_name) > 0

UNION ALL

-- These tables have only numeric, datetime, and binary LSN/transaction
-- metadata columns; none can store the original textual phone value.
SELECT N'cdc.lsn_time_mapping', COUNT_BIG(*)
FROM [llm_i6].[cdc].[lsn_time_mapping]
WHERE 1 = 0

UNION ALL

SELECT N'dbo.systranschemas', COUNT_BIG(*)
FROM [llm_i6].[dbo].[systranschemas]
WHERE 1 = 0

ORDER BY object_name;
