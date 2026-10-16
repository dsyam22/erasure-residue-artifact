-- QUERY
SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V')
  AND o.name NOT LIKE 'sys%'
ORDER BY s.name, o.name;
