-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.history_table_id,
       c.name AS column_name,
       ty.name AS type_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.name IN (N'customer_id', N'full_name', N'email', N'phone', N'valid_from', N'valid_to')
   OR ty.name IN (N'nvarchar', N'varchar', N'char', N'nchar', N'text', N'ntext', N'xml')
ORDER BY s.name, t.name, c.column_id;
