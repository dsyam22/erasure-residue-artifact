-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name;
