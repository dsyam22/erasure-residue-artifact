SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U','V','P','FN','IF','TF','TR')
ORDER BY s.name, o.name;

SELECT
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key
FROM sys.tables AS t
JOIN sys.indexes AS i ON i.object_id = t.object_id
ORDER BY t.name, i.index_id;

SELECT
    name AS trigger_name,
    OBJECT_NAME(parent_id) AS parent_object,
    is_disabled,
    is_instead_of_trigger
FROM sys.triggers
ORDER BY parent_object, name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('V','P','FN','IF','TF','TR')
ORDER BY s.name, o.name;

SELECT
    name AS default_name,
    OBJECT_NAME(parent_object_id) AS parent_object,
    definition
FROM sys.default_constraints
ORDER BY parent_object, name;

SELECT
    name AS check_name,
    OBJECT_NAME(parent_object_id) AS parent_object,
    definition
FROM sys.check_constraints
ORDER BY parent_object, name;
