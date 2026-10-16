-- QUERY
SELECT 
    c.name AS table_name,
    SUM(CASE WHEN col.name = 'customer_id' AND ty.name = 'int' THEN 1 ELSE 0 END) AS has_customer_id_int,
    SUM(CASE WHEN col.name = 'full_name' AND ty.name = 'nvarchar' THEN 1 ELSE 0 END) AS has_full_name_nvarchar,
    SUM(CASE WHEN col.name = 'email' AND ty.name = 'nvarchar' THEN 1 ELSE 0 END) AS has_email_nvarchar,
    SUM(CASE WHEN col.name = 'phone' AND ty.name = 'nvarchar' THEN 1 ELSE 0 END) AS has_phone_nvarchar
FROM sys.columns col
JOIN sys.tables c ON col.object_id = c.object_id
JOIN sys.types ty ON col.user_type_id = ty.user_type_id
WHERE c.name IN ('customer', 'customer_history')
GROUP BY c.name;
