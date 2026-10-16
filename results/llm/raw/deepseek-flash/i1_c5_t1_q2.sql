-- QUERY
SELECT t.name AS table_name, c.name AS column_name, ty.name AS type_name
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.name IN ('captured_columns','change_tables','customer','dbo_customer_CT','ddl_history','index_columns','lsn_time_mapping','systranschemas')
ORDER BY t.name, c.column_id;
