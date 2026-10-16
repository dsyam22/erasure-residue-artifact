-- QUERY
SELECT 
    OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id) AS object_name,
    c.name AS column_name
FROM sys.columns c
WHERE c.name IN ('full_name', 'email', 'phone', 'customer_id', 'member_id')
  AND OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id) NOT IN ('dbo.customer', 'dbo.member')
ORDER BY object_name, c.name;
