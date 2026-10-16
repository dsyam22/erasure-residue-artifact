-- QUERY
SELECT 
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.name IN ('customer','customer_history')
ORDER BY s.name, t.name;
