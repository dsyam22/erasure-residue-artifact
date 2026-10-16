-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE (c.name LIKE '%name%' 
   OR c.name LIKE '%email%' 
   OR c.name LIKE '%phone%' 
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%subject%')
  AND t.name != 'customer'
ORDER BY t.name, c.column_id;
