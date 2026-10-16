SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE t.name IN ('customer', 'member')
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')
ORDER BY s.name, o.name;

SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    COL_NAME(ic.object_id, ic.column_id) AS column_name
FROM sys.indexes AS i
JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id AND ic.index_id = i.index_id
WHERE i.object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
ORDER BY schema_name, table_name, i.index_id, ic.key_ordinal;

SELECT
    OBJECT_SCHEMA_NAME(d.referencing_id) AS referencing_schema,
    OBJECT_NAME(d.referencing_id) AS referencing_object,
    d.referenced_entity_name,
    d.referenced_id
FROM sys.sql_expression_dependencies AS d
WHERE d.referenced_entity_name IN ('customer', 'member')
   OR d.referencing_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'));
