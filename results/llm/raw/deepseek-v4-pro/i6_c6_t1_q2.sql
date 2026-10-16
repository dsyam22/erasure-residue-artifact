-- QUERY
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%contact%'
   OR c.name LIKE '%mobile%'
ORDER BY s.name, t.name, c.name;
