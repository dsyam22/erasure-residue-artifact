SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.column_id
FROM sys.schemas AS s
JOIN sys.tables AS t
    ON t.schema_id = s.schema_id
JOIN sys.columns AS c
    ON c.object_id = t.object_id
JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;

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
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%member%'
   OR m.definition LIKE '%full_name%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    c.name AS column_name,
    ic.key_ordinal,
    ic.is_included_column
FROM sys.indexes AS i
JOIN sys.tables AS t
    ON t.object_id = i.object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id
   AND ic.index_id = i.index_id
JOIN sys.columns AS c
    ON c.object_id = ic.object_id
   AND c.column_id = ic.column_id
WHERE t.name IN ('customer', 'member')
ORDER BY s.name, t.name, i.name, ic.key_ordinal, ic.index_column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.lock_escalation_desc,
    t.is_memory_optimized,
    t.temporal_type_desc,
    t.is_tracked_by_cdc
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE t.name IN ('customer', 'member');

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    p.name AS partition_function,
    ps.name AS partition_scheme
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.indexes AS i
    ON i.object_id = t.object_id
   AND i.index_id IN (0, 1)
LEFT JOIN sys.partition_schemes AS ps
    ON ps.data_space_id = i.data_space_id
LEFT JOIN sys.partition_functions AS p
    ON p.function_id = ps.function_id
WHERE t.name IN ('customer', 'member');

SELECT
    DB_NAME() AS database_name,
    name AS file_name,
    type_desc,
    physical_name,
    state_desc
FROM sys.database_files;
