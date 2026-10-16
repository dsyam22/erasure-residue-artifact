-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'dbo'
  AND (c.name LIKE '%name%' OR c.name LIKE '%email%' OR c.name LIKE '%phone%' OR c.name LIKE '%customer%')
ORDER BY t.name, c.name;
