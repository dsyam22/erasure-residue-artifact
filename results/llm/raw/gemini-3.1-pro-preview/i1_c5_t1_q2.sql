-- QUERY
SELECT t.name AS table_name, h.name AS history_table_name, h.schema_id
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.name = 'customer';
