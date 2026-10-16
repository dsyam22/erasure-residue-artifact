SELECT
    N'dbo.customer' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
   OR CHARINDEX(N'Subject_0000042', full_name) > 0
   OR CHARINDEX(N'subject42@example.invalid', email) > 0
   OR CHARINDEX(N'+1-555-0000042', phone) > 0

UNION ALL

SELECT
    N'reporting.customer_replica' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM reporting.customer_replica
WHERE customer_id = 42
   OR CHARINDEX(N'Subject_0000042', full_name) > 0
   OR CHARINDEX(N'subject42@example.invalid', email) > 0
   OR CHARINDEX(N'+1-555-0000042', phone) > 0;
