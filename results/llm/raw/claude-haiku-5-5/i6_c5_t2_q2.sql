-- QUERY
SELECT c.name AS column_name, ty.name AS type_name, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'cdc.dbo_customer_CT')
ORDER BY c.column_id;
