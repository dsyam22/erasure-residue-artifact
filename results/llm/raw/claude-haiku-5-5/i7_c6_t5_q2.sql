-- QUERY
SELECT o.type_desc, s.name AS schema_name, o.name AS object_name, c.name AS column_name, ty.name AS data_type
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
LEFT JOIN sys.columns c ON c.object_id = o.object_id
LEFT JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE o.is_ms_shipped = 0
  AND o.type NOT IN ('S', 'IT', 'PK', 'UQ', 'D', 'F', 'SQ')
ORDER BY s.name, o.name, c.column_id;
