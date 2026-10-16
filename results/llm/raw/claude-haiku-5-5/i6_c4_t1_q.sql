SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.is_ms_shipped,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.columns AS c
    ON c.object_id = t.object_id
LEFT JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    v.name AS view_name,
    m.definition
FROM sys.views AS v
JOIN sys.schemas AS s
    ON s.schema_id = v.schema_id
LEFT JOIN sys.sql_modules AS m
    ON m.object_id = v.object_id
ORDER BY s.name, v.name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
JOIN sys.sql_modules AS m
    ON m.object_id = o.object_id
WHERE o.type IN ('P', 'FN', 'IF', 'TF', 'TR')
ORDER BY s.name, o.name;
