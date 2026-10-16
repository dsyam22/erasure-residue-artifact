-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       h.name AS history_table_name,
       t.is_tracked_by_cdc
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS h ON h.object_id = t.history_table_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;
