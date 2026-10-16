-- QUERY
SELECT 
    t.name AS table_name,
    t.temporal_type_desc,
    h.name AS history_table_name,
    s.name AS history_schema_name
FROM sys.tables t
LEFT JOIN sys.tables h ON t.history_table_id = h.object_id
LEFT JOIN sys.schemas s ON h.schema_id = s.schema_id
WHERE t.name = 'customer' AND t.schema_id = SCHEMA_ID('dbo');
