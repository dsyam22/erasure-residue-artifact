-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name IN ('customer', 'member', 'member_history', 'dbo_customer_CT', 'captured_columns', 'change_tables', 'ddl_history', 'index_columns', 'lsn_time_mapping', 'systranschemas')
ORDER BY t.name, c.column_id;
