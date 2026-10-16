SELECT DB_NAME() AS database_name, @@SERVERNAME AS server_name;

SELECT s.name AS schema_name
FROM sys.schemas AS s
WHERE s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY s.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type,
    t.temporal_type_desc,
    hist_s.name AS history_schema_name,
    hist_t.name AS history_table_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables AS hist_t ON t.history_table_id = hist_t.object_id
LEFT JOIN sys.schemas AS hist_s ON hist_t.schema_id = hist_s.schema_id
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON t.object_id = c.object_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.partitions AS p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    m.definition
FROM sys.views AS v
JOIN sys.schemas AS s ON v.schema_id = s.schema_id
LEFT JOIN sys.sql_modules AS m ON v.object_id = m.object_id
ORDER BY s.name, v.name;

SELECT 
    s.name AS schema_name,
    syn.name AS synonym_name,
    syn.base_object_name
FROM sys.synonyms AS syn
JOIN sys.schemas AS s ON syn.schema_id = s.schema_id
ORDER BY s.name, syn.name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON o.schema_id = s.schema_id
LEFT JOIN sys.sql_modules AS m ON o.object_id = m.object_id
WHERE o.type IN ('P', 'FN', 'IF', 'TF', 'TR')
ORDER BY s.name, o.name;
