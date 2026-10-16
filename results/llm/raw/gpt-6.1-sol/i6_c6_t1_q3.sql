-- QUERY
SELECT s.name AS schema_name, t.name AS table_name, t.is_ms_shipped,
       c.column_id, c.name AS column_name, ty.name AS data_type
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE s.name = N'cdc'
ORDER BY t.name, c.column_id;
