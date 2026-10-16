-- SCRIPT
-- Scope: accessible customer rows, persisted Query Store text/plans,
-- and stored SQL module definitions in llm_i8.
-- This is not proof of physical erasure: transaction-log inspection was
-- denied. Deleted/ghost records, unallocated pages, version stores, backups,
-- and other inaccessible storage cannot be verified by this script.
-- Zero counts mean no matches in the objects checked, not complete erasure.

DECLARE @full_name nvarchar(200),
        @email nvarchar(400),
        @phone nvarchar(60);

SELECT @full_name = N'Subject_' + N'0000042',
       @email = N'subject42' + N'@example.invalid',
       @phone = N'+1-555-' + N'0000042';

SELECT N'dbo.customer' AS object_name,
       COUNT_BIG(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
   OR CHARINDEX(@full_name, full_name) > 0
   OR CHARINDEX(@email, email) > 0
   OR CHARINDEX(@phone, phone) > 0

UNION ALL

SELECT N'sys.query_store_query_text',
       COUNT_BIG(*)
FROM sys.query_store_query_text
WHERE CHARINDEX(@full_name, query_sql_text) > 0
   OR CHARINDEX(@email, query_sql_text) > 0
   OR CHARINDEX(@phone, query_sql_text) > 0

UNION ALL

SELECT N'sys.query_store_plan',
       COUNT_BIG(*)
FROM sys.query_store_plan
WHERE CHARINDEX(@full_name, query_plan) > 0
   OR CHARINDEX(@email, query_plan) > 0
   OR CHARINDEX(@phone, query_plan) > 0

UNION ALL

SELECT N'sys.sql_modules',
       COUNT_BIG(*)
FROM sys.sql_modules
WHERE CHARINDEX(@full_name, definition) > 0
   OR CHARINDEX(@email, definition) > 0
   OR CHARINDEX(@phone, definition) > 0;
