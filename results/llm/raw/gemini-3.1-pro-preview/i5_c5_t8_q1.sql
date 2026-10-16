-- QUERY
SELECT 
    t.name AS current_table, 
    h.name AS history_table,
    s.name AS history_schema
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
JOIN sys.schemas s ON h.schema_id = s.schema_id
WHERE t.name = 'customer' AND SCHEMA_NAME(t.schema_id) = 'dbo';
