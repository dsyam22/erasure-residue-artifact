-- QUERY
SELECT
    o.object_id,
    o.type,
    s.name AS schema_name,
    o.name AS object_name
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V')
ORDER BY s.name, o.name;
