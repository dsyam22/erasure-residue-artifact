-- QUERY
SELECT 
    OBJECT_SCHEMA_NAME(t.object_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
WHERE c.name IN ('full_name','email','phone','customer_id','member_id')
  AND t.name NOT IN ('customer','member','member_history','dbo_customer_CT')
ORDER BY schema_name, table_name, column_name;
