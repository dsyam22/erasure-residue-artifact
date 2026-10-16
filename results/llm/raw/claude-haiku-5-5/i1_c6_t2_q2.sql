-- QUERY
SELECT 'cdc.dbo_customer_CT' AS object_name,
       COUNT(*) AS matching_rows
FROM cdc.dbo_customer_CT
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
UNION ALL
SELECT CONCAT(s.name, '.', t.name), SUM(p.rows)
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE s.name <> 'cdc'
GROUP BY s.name, t.name;
