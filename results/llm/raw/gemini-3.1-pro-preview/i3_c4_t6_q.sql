SELECT 
    schema_name(t.schema_id) AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    object_name(t.history_table_id) AS history_table_name
FROM sys.tables t
WHERE t.name IN ('customer', 'member');
