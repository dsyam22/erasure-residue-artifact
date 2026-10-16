-- QUERY
SELECT TOP (100) s.name AS schema_name, o.name AS object_name, c.name AS column_name, t.name AS data_type
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.columns c ON c.object_id = o.object_id
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE o.name IN ('dbo_customer_CT','change_tables','captured_columns','ddl_history','index_columns','lsn_time_mapping','systranschemas')
ORDER BY s.name, o.name, c.column_id;
