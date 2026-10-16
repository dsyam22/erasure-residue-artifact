-- QUERY
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar','varchar','char','nchar','text','ntext')
  AND s.name = 'dbo'
  AND t.name NOT IN ('customer','customer_history')
ORDER BY s.name, t.name, c.column_id;
