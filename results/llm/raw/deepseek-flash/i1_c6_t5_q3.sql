-- QUERY
SELECT s.name AS schema_name, o.name AS object_name, c.name AS column_name
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.columns c ON c.object_id = o.object_id
WHERE o.type IN ('U','V')
  AND (c.name LIKE '%name%' OR c.name LIKE '%email%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%address%' OR c.name LIKE '%customer%' OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%' OR c.name LIKE '%contact%' OR c.name LIKE '%data%')
ORDER BY s.name, o.name, c.column_id;
