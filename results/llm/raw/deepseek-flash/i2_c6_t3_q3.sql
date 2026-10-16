-- QUERY
SELECT 
    c.name AS column_name,
    ty.name AS data_type
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.customer_history');
