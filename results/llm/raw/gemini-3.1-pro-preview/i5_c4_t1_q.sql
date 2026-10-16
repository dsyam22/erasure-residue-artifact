SELECT 
    schema_name(t.schema_id) AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    schema_name(h.schema_id) AS history_schema_name,
    h.name AS history_table_name
FROM sys.tables t
LEFT JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.name = 'customer' AND schema_name(t.schema_id) = 'dbo';
