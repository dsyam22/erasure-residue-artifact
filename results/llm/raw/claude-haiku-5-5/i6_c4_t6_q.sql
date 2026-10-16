SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE m.definition LIKE '%phone%';

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%mobile%'
   OR c.name LIKE '%contact%';

SELECT
    DB_NAME() AS database_name,
    SUM(CASE WHEN is_ms_shipped = 0 THEN 1 ELSE 0 END) AS user_table_count
FROM sys.tables;
