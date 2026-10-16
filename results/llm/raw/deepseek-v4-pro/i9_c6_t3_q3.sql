-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name NOT IN ('customer', 'customer_history')
  AND (c.name LIKE '%name%' 
   OR c.name LIKE '%email%' 
   OR c.name LIKE '%phone%' 
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%full%')
ORDER BY t.name, c.column_id;
