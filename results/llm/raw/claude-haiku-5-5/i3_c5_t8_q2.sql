-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       h.name AS history_table_name,
       c.name AS column_name,
       ty.name AS data_type
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS h ON h.object_id = t.history_table_id
LEFT JOIN sys.columns AS c ON c.object_id = t.object_id
LEFT JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;
