-- QUERY
SELECT s.name AS schema_name, o.name AS object_name, o.type_desc,
       sy.base_object_name
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.synonyms AS sy ON sy.object_id = o.object_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, o.name;

SELECT customer_id, full_name, email
FROM dbo.customer
WHERE customer_id = 42
   OR CHARINDEX(N'+1-555-0000042', full_name COLLATE Latin1_General_100_BIN2) > 0
   OR CHARINDEX(N'+1-555-0000042', email COLLATE Latin1_General_100_BIN2) > 0;
