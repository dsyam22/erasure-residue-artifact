-- QUERY
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       o.temporal_type_desc,
       c.name AS column_name,
       t.name AS data_type
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.columns AS c ON c.object_id = o.object_id
LEFT JOIN sys.types AS t ON t.user_type_id = c.user_type_id
WHERE o.type IN ('U', 'V')
ORDER BY s.name, o.name, c.column_id;
