-- QUERY
SELECT 
    t.name AS table_name, 
    s.name AS schema_name,
    h.name AS history_table_name,
    hs.name AS history_schema_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.tables h ON t.history_table_id = h.object_id
JOIN sys.schemas hs ON h.schema_id = hs.schema_id
WHERE t.name = 'customer' AND s.name = 'dbo';
