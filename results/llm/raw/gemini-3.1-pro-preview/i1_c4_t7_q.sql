SELECT t.schema_id, SCHEMA_NAME(t.schema_id) AS schema_name, t.name AS table_name, 
       c.name AS column_name, ty.name AS data_type, 
       t.temporal_type_desc, 
       OBJECT_NAME(t.history_table_id) AS history_table_name
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY schema_name, table_name, c.column_id;
