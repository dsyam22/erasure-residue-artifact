SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    h.name AS history_table_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id;
