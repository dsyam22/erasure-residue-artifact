-- QUERY
SELECT c.name AS col_name, t.name AS type_name, c.max_length
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.customer');
