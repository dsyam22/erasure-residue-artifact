-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE TYPE_NAME(c.user_type_id) IN ('nvarchar', 'varchar', 'char', 'nchar', 'text', 'ntext')
  AND t.name NOT IN ('captured_columns', 'change_tables', 'ddl_history', 'index_columns', 'lsn_time_mapping', 'systranschemas')
ORDER BY t.name, c.column_id;
