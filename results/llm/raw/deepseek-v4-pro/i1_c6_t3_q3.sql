-- QUERY
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE (c.name LIKE '%name%' OR c.name LIKE '%email%' OR c.name LIKE '%phone%' OR c.name LIKE '%customer%')
AND t.name NOT IN ('customer', 'captured_columns', 'change_tables', 'dbo_customer_CT', 'ddl_history', 'index_columns', 'systranschemas')
ORDER BY s.name, t.name, c.column_id;
