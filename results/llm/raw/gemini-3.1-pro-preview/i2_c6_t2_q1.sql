-- QUERY
SELECT t.name AS table_name, h.name AS history_table_name, schema_name(h.schema_id) AS history_schema_name
FROM sys.tables t
LEFT JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.name = 'customer' AND t.schema_id = schema_id('dbo');
