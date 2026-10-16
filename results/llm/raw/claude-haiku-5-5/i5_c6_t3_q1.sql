-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext', 'xml', 'sysname')
ORDER BY s.name, t.name, c.column_id;
