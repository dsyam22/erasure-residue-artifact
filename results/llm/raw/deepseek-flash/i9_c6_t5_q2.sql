-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
WHERE c.name IN ('customer_id','full_name','email','phone','valid_from','valid_to')
  AND t.name <> 'customer'
ORDER BY t.name, c.name;
