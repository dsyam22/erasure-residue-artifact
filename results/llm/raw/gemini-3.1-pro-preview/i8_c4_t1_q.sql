SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type,
    t.temporal_type_desc,
    h.name AS history_table_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables h ON t.history_table_id = h.object_id;
