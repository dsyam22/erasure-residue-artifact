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
WHERE s.name IN ('dbo')
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V')
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    o.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key
FROM sys.indexes AS i
JOIN sys.objects AS o ON o.object_id = i.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type = 'U'
ORDER BY s.name, o.name, i.index_id;

SELECT
    s.name AS schema_name,
    o.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.columns AS c
JOIN sys.objects AS o ON o.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE o.type = 'U'
  AND (c.name LIKE '%name%'
       OR c.name LIKE '%email%'
       OR c.name LIKE '%phone%'
       OR c.name LIKE '%customer%'
       OR c.name LIKE '%member%'
       OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%'
       OR c.name LIKE '%address%'
       OR c.name LIKE '%dob%'
       OR c.name LIKE '%birth%')
ORDER BY s.name, o.name, c.name;

SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id) AS object_name,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
WHERE o.type IN ('V', 'P', 'FN', 'IF', 'TF', 'TR')
  AND (m.definition LIKE '%customer%'
       OR m.definition LIKE '%member%'
       OR m.definition LIKE '%email%'
       OR m.definition LIKE '%phone%'
       OR m.definition LIKE '%full_name%'
       OR m.definition LIKE '%subject%')
ORDER BY schema_name, object_name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS total_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE s.name = 'dbo'
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text', 'xml')
ORDER BY s.name, t.name, c.column_id;
