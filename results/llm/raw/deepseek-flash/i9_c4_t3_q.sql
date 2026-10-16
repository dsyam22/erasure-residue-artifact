SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.column_id
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE t.name = 'customer'
ORDER BY s.name, t.name, c.column_id;

SELECT
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    COL_NAME(ic.object_id, ic.column_id) AS column_name
FROM sys.indexes AS i
JOIN sys.indexes AS ix ON ix.object_id = i.object_id AND ix.index_id = i.index_id
JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
WHERE i.object_id = OBJECT_ID('dbo.customer')
ORDER BY i.index_id, ic.key_ordinal;

SELECT
    OBJECT_SCHEMA_NAME(v.object_id) AS schema_name,
    OBJECT_NAME(v.object_id) AS object_name,
    v.name AS view_name,
    v.type_desc
FROM sys.objects AS v
WHERE v.type IN ('V','P','FN','IF','TF','TR')
  AND OBJECT_DEFINITION(v.object_id) LIKE '%customer%'
ORDER BY schema_name, object_name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U','V')
ORDER BY s.name, o.name;
