-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext', N'xml', N'sysname')
   OR c.name LIKE N'%email%'
   OR c.name LIKE N'%phone%'
   OR c.name LIKE N'%name%'
ORDER BY s.name, t.name, c.column_id;
