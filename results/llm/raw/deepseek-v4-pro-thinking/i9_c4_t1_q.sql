SELECT DB_NAME() AS database_name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.type_desc,
    t.temporal_type_desc,
    t.history_table_id,
    hist_schema.name AS history_schema_name,
    hist.name AS history_table_name,
    t.create_date,
    t.modify_date
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables AS hist ON t.history_table_id = hist.object_id
LEFT JOIN sys.schemas AS hist_schema ON hist.schema_id = hist_schema.schema_id
WHERE t.is_ms_shipped = 0
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
    c.is_computed,
    c.is_hidden,
    c.collation_name
FROM sys.columns AS c
JOIN sys.tables AS t ON c.object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    p.index_id,
    p.partition_number,
    p.rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.partitions AS p ON t.object_id = p.object_id
WHERE t.is_ms_shipped = 0
  AND p.index_id IN (0, 1)
ORDER BY s.name, t.name, p.partition_number;

SELECT 
    OBJECT_SCHEMA_NAME(p.object_id) AS schema_name,
    OBJECT_NAME(p.object_id) AS table_name,
    p.name AS period_name,
    p.period_type_desc,
    c1.name AS start_column,
    c2.name AS end_column
FROM sys.periods AS p
JOIN sys.columns AS c1 ON p.object_id = c1.object_id AND p.start_column_id = c1.column_id
JOIN sys.columns AS c2 ON p.object_id = c2.object_id AND p.end_column_id = c2.column_id
ORDER BY schema_name, table_name, p.name;

SELECT 
    fk.name AS foreign_key_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS referencing_schema,
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    c1.name AS referencing_column,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    c2.name AS referenced_column
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns AS c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
JOIN sys.columns AS c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id
WHERE fk.is_ms_shipped = 0
ORDER BY referencing_schema, referencing_table, foreign_key_name;

SELECT 
    OBJECT_SCHEMA_NAME(v.object_id) AS schema_name,
    v.name AS view_name,
    m.definition
FROM sys.views AS v
JOIN sys.sql_modules AS m ON v.object_id = m.object_id
WHERE v.is_ms_shipped = 0
ORDER BY schema_name, view_name;

SELECT 
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
    OBJECT_NAME(tr.parent_id) AS parent_object,
    tr.name AS trigger_name,
    tr.is_disabled,
    m.definition
FROM sys.triggers AS tr
JOIN sys.sql_modules AS m ON tr.object_id = m.object_id
WHERE tr.is_ms_shipped = 0
  AND tr.parent_id > 0
ORDER BY parent_schema, parent_object, trigger_name;
