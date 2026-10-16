-- QUERY
SELECT s.name AS schema_name, o.name AS object_name, c.name AS column_name
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.columns c ON c.object_id = o.object_id
WHERE o.type IN ('U','V')
  AND c.system_type_id IN (167, 231, 175, 239, 35)  -- varchar, nvarchar, char, nchar, text/ntext
ORDER BY s.name, o.name, c.column_id;
