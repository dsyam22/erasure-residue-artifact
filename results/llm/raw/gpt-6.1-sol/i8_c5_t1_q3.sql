-- QUERY
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    CAST(NULL AS nvarchar(1035)) AS base_object_name
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE o.type = 'V'
  AND o.is_ms_shipped = 0
UNION ALL
SELECT
    s.name,
    sn.name,
    N'SYNONYM',
    NULL,
    NULL,
    NULL,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON s.schema_id = sn.schema_id
ORDER BY schema_name, object_name, column_id;
