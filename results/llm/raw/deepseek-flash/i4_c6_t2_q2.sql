-- QUERY
SELECT c.table_schema, c.table_name, c.column_name
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.table_schema = 'dbo'
  AND c.table_name IN ('customer','member','member_history','dbo_customer_CT')
ORDER BY c.table_name, c.ordinal_position;
