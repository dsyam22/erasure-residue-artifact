SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.column_id,
    c.name AS column_name,
    t.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.objects AS o
JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
JOIN sys.columns AS c
    ON c.object_id = o.object_id
JOIN sys.types AS t
    ON t.user_type_id = c.user_type_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, o.name, c.column_id;
