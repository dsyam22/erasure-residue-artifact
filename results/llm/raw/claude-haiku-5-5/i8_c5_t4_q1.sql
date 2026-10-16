-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       t.temporal_type,
       t.is_ms_shipped
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
LEFT JOIN sys.tables h ON h.object_id = t.history_table_id
ORDER BY s.name, t.name, c.column_id;
