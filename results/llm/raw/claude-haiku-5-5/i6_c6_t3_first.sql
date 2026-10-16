I haven't run a query yet, and my earlier script was written without inspecting the database. I'll run one now. This batch lists every user table and its character columns, so I can see where the phone number could be stored.

-- QUERY
SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name, ty.name AS type_name, c.max_length
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml')
ORDER BY s.name, t.name, c.column_id;
