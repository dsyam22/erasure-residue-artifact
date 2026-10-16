-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       h.name AS history_schema,
       ht.name AS history_table,
       t.is_memory_optimized
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas h ON h.schema_id = ht.schema_id
ORDER BY s.name, t.name;
