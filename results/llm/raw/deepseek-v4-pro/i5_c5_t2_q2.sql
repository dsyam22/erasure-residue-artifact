-- QUERY
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND (DATA_TYPE IN ('int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'money', 'smallmoney', 'float', 'real')
       OR COLUMN_NAME IN ('customer_id', 'id', 'customer', 'cust_id', 'cust_no', 'customer_no', 'customer_number'))
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;
