SELECT 
    DB_NAME() AS database_name,
    @@VERSION AS sql_version;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.type_desc,
    t.is_ms_shipped,
    t.is_external,
    t.temporal_type,
    t.temporal_type_desc,
    t.history_table_id,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema_name,
    OBJECT_NAME(t.history_table_id) AS history_table_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
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
    c.collation_name,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type,
    c.generated_always_type_desc,
    c.is_hidden
FROM sys.columns AS c
JOIN sys.tables AS t ON c.object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    OBJECT_SCHEMA_NAME(p.object_id) AS schema_name,
    OBJECT_NAME(p.object_id) AS table_name,
    p.name AS period_name,
    p.period_type,
    p.period_type_desc,
    c_start.name AS start_column,
    c_end.name AS end_column
FROM sys.periods AS p
LEFT JOIN sys.columns AS c_start
    ON c_start.object_id = p.object_id
   AND c_start.column_id = p.start_column_id
LEFT JOIN sys.columns AS c_end
    ON c_end.object_id = p.object_id
   AND c_end.column_id = p.end_column_id
ORDER BY schema_name, table_name, p.name;

SELECT 
    tr.name AS trigger_name,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
    OBJECT_NAME(tr.parent_id) AS parent_table,
    tr.type_desc,
    tr.is_disabled,
    tr.is_instead_of_trigger
FROM sys.triggers AS tr
WHERE tr.parent_class = 1
ORDER BY tr.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type
FROM sys.columns AS c
JOIN sys.tables AS t ON c.object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE c.name LIKE '%name%'
   OR c.name LIKE '%email%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%member%'
ORDER BY s.name, t.name, c.column_id;
