SELECT 
    s.name AS schema_name,
    t.name AS table_name, 
    c.name AS column_name, 
    t.temporal_type_desc, 
    OBJECT_NAME(t.history_table_id) AS history_table_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name IN ('customer_id', 'full_name', 'email', 'phone')
ORDER BY s.name, t.name, c.column_id;
