-- SCRIPT
-- Checks accessible live customer rows and persisted Query Store text/plans.
-- A zero count does NOT establish complete erasure: transaction-log access
-- was denied. Deleted record bytes, version stores, unallocated pages and
-- backups are not verified by this script.
-- Query Store counts refer to stored text/plan rows, not customer records.
WITH subject AS
(
    SELECT
        CAST(42 AS int) AS customer_id,
        CONVERT(nvarchar(100), N'Subject_' + N'0000042') AS full_name,
        CONVERT(nvarchar(100), N'subject42' + N'@example.invalid') AS email,
        CONVERT(nvarchar(100), N'+1-555-' + N'0000042') AS phone
)
SELECT N'dbo.customer' AS object_name, COUNT_BIG(*) AS rows_found
FROM dbo.customer AS c
CROSS JOIN subject AS s
WHERE c.customer_id = s.customer_id
   OR CHARINDEX(s.full_name, c.full_name) > 0
   OR CHARINDEX(s.email, c.email) > 0
   OR CHARINDEX(s.phone, c.phone) > 0

UNION ALL

SELECT N'sys.query_store_query_text', COUNT_BIG(*)
FROM sys.query_store_query_text AS q
CROSS JOIN subject AS s
WHERE CHARINDEX(s.full_name, q.query_sql_text) > 0
   OR CHARINDEX(s.email, q.query_sql_text) > 0
   OR CHARINDEX(s.phone, q.query_sql_text) > 0

UNION ALL

SELECT N'sys.query_store_plan', COUNT_BIG(*)
FROM sys.query_store_plan AS p
CROSS JOIN subject AS s
WHERE CHARINDEX(s.full_name, p.query_plan) > 0
   OR CHARINDEX(s.email, p.query_plan) > 0
   OR CHARINDEX(s.phone, p.query_plan) > 0;
