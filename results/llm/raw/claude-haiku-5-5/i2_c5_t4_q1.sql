-- QUERY
SELECT s.name AS schema_name, t.name AS table_name, t.temporal_type_desc, t.history_table_id,
       c.name AS column_name, TYPE_NAME(c.user_type_id) AS data_type
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE TYPE_NAME(c.user_type_id) IN ('nvarchar','varchar','nchar','char','ntext','text','xml','sysname')
   OR c.name LIKE '%id%'
ORDER BY s.name, t.name, c.column_id;
