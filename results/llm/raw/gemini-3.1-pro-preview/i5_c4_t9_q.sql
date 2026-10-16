SELECT 
    t.name AS table_name,
    h.name AS history_table_name,
    h.schema_id AS history_schema_id,
    s.name AS history_schema_name
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
JOIN sys.schemas s ON h.schema_id = s.schema_id
WHERE t.name = 'customer' AND t.schema_id = SCHEMA_ID('dbo');
