SELECT 'TABLE_LIST' AS result_set;
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.partitions AS p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT 'COLUMN_LIST' AS result_set;
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
    c.is_computed,
    cc.definition AS computed_definition
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON t.object_id = c.object_id
LEFT JOIN sys.computed_columns AS cc 
    ON c.object_id = cc.object_id AND c.column_id = cc.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT 'PHONE_NAME_SEARCH' AS result_set;
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON t.object_id = c.object_id
WHERE c.name LIKE '%phone%'
   OR c.name LIKE '%mobile%'
   OR c.name LIKE '%fax%'
   OR c.name LIKE '%contact%'
ORDER BY s.name, t.name, c.name;

SELECT 'PHONE_DEFINITION_SEARCH' AS result_set;
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    cc.definition AS computed_definition,
    dc.definition AS default_constraint_definition
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON t.object_id = c.object_id
LEFT JOIN sys.computed_columns AS cc 
    ON c.object_id = cc.object_id AND c.column_id = cc.column_id
LEFT JOIN sys.default_constraints AS dc 
    ON c.default_object_id = dc.object_id
WHERE cc.definition LIKE '%phone%'
   OR dc.definition LIKE '%phone%'
ORDER BY s.name, t.name, c.name;

SELECT 'VIEW_LIST' AS result_set;
SELECT
    s.name AS schema_name,
    v.name AS view_name,
    v.definition
FROM sys.views AS v
JOIN sys.schemas AS s ON v.schema_id = s.schema_id
ORDER BY s.name, v.name;
