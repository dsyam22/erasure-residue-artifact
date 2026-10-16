SELECT 
    t.name AS table_name,
    t.temporal_type_desc,
    h.name AS history_table_name,
    SCHEMA_NAME(h.schema_id) AS history_schema_name
FROM sys.tables t
LEFT JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.name = 'customer' AND t.schema_id = SCHEMA_ID('dbo');
