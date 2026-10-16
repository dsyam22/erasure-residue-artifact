SELECT DB_NAME() AS current_database, SERVERPROPERTY('ProductVersion') AS sql_version;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.is_memory_optimized,
    t.is_filetable
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
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
    c.is_column_set
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON t.object_id = c.object_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

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
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON m.object_id = o.object_id
JOIN sys.schemas AS s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('P','FN','IF','TF','TR')
  AND (
        m.definition LIKE '%phone%'
     OR m.definition LIKE '%mobile%'
     OR m.definition LIKE '%tel%'
     OR m.definition LIKE '%555%'
     OR m.definition LIKE '%subject42%'
     OR m.definition LIKE '%Subject_0000042%'
     OR m.definition LIKE '%+1-555-0000042%'
     OR m.definition LIKE '%subject42@example.invalid%'
  )
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON t.object_id = c.object_id
WHERE t.is_ms_shipped = 0
  AND (
        c.name LIKE '%phone%'
     OR c.name LIKE '%mobile%'
     OR c.name LIKE '%tel%'
     OR c.name LIKE '%contact%'
     OR c.name LIKE '%number%'
  )
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    cc.name AS check_constraint_name,
    cc.definition
FROM sys.check_constraints AS cc
JOIN sys.tables AS t ON cc.parent_object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE cc.is_ms_shipped = 0
  AND (
        cc.definition LIKE '%phone%'
     OR cc.definition LIKE '%mobile%'
     OR cc.definition LIKE '%tel%'
     OR cc.definition LIKE '%555%'
     OR cc.definition LIKE '%subject42%'
     OR cc.definition LIKE '%+1-555-0000042%'
     OR cc.definition LIKE '%subject42@example.invalid%'
  )
ORDER BY s.name, t.name, cc.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    dc.name AS default_constraint_name,
    dc.definition
FROM sys.default_constraints AS dc
JOIN sys.tables AS t ON dc.parent_object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE dc.is_ms_shipped = 0
  AND (
        dc.definition LIKE '%phone%'
     OR dc.definition LIKE '%mobile%'
     OR dc.definition LIKE '%555%'
     OR dc.definition LIKE '%subject42%'
     OR dc.definition LIKE '%+1-555-0000042%'
     OR dc.definition LIKE '%subject42@example.invalid%'
  )
ORDER BY s.name, t.name, dc.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    cc.definition
FROM sys.computed_columns AS cc
JOIN sys.tables AS t ON cc.object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE t.is_ms_shipped = 0
  AND (
        cc.definition LIKE '%phone%'
     OR cc.definition LIKE '%mobile%'
     OR cc.definition LIKE '%tel%'
     OR cc.definition LIKE '%555%'
     OR cc.definition LIKE '%subject42%'
     OR cc.definition LIKE '%+1-555-0000042%'
     OR cc.definition LIKE '%subject42@example.invalid%'
  )
ORDER BY s.name, t.name, c.name;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON sn.schema_id = s.schema_id
ORDER BY s.name, sn.name;
