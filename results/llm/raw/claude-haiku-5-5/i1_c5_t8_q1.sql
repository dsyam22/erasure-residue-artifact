-- QUERY
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar','text','ntext','xml','int','bigint','uniqueidentifier')
ORDER BY s.name, t.name, c.column_id;
