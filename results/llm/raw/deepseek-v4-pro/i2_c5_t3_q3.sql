-- QUERY
SELECT 
    t.name AS table_name
FROM sys.tables t
WHERE t.schema_id = SCHEMA_ID('dbo')
ORDER BY t.name;
