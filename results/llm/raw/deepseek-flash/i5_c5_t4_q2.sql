-- QUERY
SELECT c.table_schema, c.table_name, c.column_name, c.data_type
FROM information_schema.columns c
WHERE c.table_name IN ('customer','customer_history')
ORDER BY c.table_name, c.ordinal_position;
