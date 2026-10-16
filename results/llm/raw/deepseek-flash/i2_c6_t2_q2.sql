-- QUERY
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')
ORDER BY s.name, o.name;
