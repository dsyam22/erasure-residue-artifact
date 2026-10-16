-- QUERY
SELECT c.name, t.name as type_name
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('cdc.dbo_customer_CT');
