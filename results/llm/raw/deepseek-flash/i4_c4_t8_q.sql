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
WHERE t.name IN ('customer', 'member')
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    o.object_id
FROM sys.objects AS o
JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')
ORDER BY o.type_desc, s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns
FROM sys.indexes AS i
JOIN sys.tables AS t
    ON t.object_id = i.object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns AS c
    ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE t.name IN ('customer', 'member')
GROUP BY s.name, t.name, i.name, i.type_desc
ORDER BY s.name, t.name, i.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.schemas AS s
JOIN sys.tables AS t
    ON t.schema_id = s.schema_id
JOIN sys.columns AS c
    ON c.object_id = t.object_id
WHERE c.name IN ('customer_id', 'member_id', 'full_name', 'email', 'phone')
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
    d.name AS database_name,
    d.collation_name,
    d.compatibility_level
FROM sys.databases AS d
WHERE d.database_id = DB_ID();
