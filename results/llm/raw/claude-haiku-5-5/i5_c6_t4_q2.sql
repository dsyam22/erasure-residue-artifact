-- QUERY
SELECT s.name AS schema_name, t.name AS table_name, t.temporal_type_desc, t.history_table_id, h.name AS history_table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables h ON h.object_id = t.history_table_id
ORDER BY s.name, t.name;
