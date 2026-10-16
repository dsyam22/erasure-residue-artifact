SELECT t.name AS table_name, c.name AS column_name, t.temporal_type, t.history_table_id
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name IN ('customer_id', 'full_name', 'email', 'phone')
ORDER BY t.name, c.column_id;
