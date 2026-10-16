SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.schemas AS s
JOIN sys.tables AS t
    ON t.schema_id = s.schema_id
JOIN sys.columns AS c
    ON c.object_id = t.object_id
JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
WHERE s.name IN ('dbo')
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint
FROM sys.indexes AS i
JOIN sys.tables AS t
    ON t.object_id = i.object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE i.name IS NOT NULL
ORDER BY s.name, t.name, i.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    fk.name AS foreign_key_name,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table
FROM sys.foreign_keys AS fk
JOIN sys.tables AS t
    ON t.object_id = fk.parent_object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
ORDER BY s.name, t.name, fk.name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o
    ON o.object_id = m.object_id
JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
ORDER BY s.name, o.name;

SELECT
    DB_NAME() AS database_name,
    name AS file_name,
    physical_name,
    type_desc,
    state_desc
FROM sys.database_files;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
JOIN sys.partitions AS p
    ON p.object_id = t.object_id
   AND p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
