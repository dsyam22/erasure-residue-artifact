-- QUERY
SELECT 'dbo.customer' AS object_name,
       COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
UNION ALL
SELECT 'reporting.customer_replica',
       COUNT(*)
FROM reporting.customer_replica
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
UNION ALL
SELECT CONCAT(s.name, '.', o.name) + ' (' + o.type_desc + ')',
       0
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('V', 'P', 'FN', 'IF', 'TF')
  AND s.name NOT IN ('sys', 'INFORMATION_SCHEMA');
