-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND c.name IN ('customer_id','full_name','email','phone')
ORDER BY t.name, c.name;
