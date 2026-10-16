SELECT 
    t.name AS table_name,
    t.temporal_type_desc,
    h.name AS history_table_name,
    s.name AS history_schema_name
FROM sys.tables t
LEFT JOIN sys.tables h ON t.history_table_id = h.object_id
LEFT JOIN sys.schemas s ON h.schema_id = s.schema_id
WHERE t.name = 'customer' AND t.schema_id = SCHEMA_ID('dbo');

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name IN ('customer_id', 'full_name', 'email', 'phone')
ORDER BY s.name, t.name, c.column_id;
