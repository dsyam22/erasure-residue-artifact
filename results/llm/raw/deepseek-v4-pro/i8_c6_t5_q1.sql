-- QUERY
SELECT 
    t.name AS table_name,
    s.name AS schema_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE 
    c.name IN ('customer_id', 'full_name', 'email', 'phone')
    OR c.name LIKE '%name%'
    OR c.name LIKE '%email%'
    OR c.name LIKE '%phone%'
    OR c.name LIKE '%customer%'
ORDER BY s.name, t.name, c.name;
