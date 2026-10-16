SET NOCOUNT ON;

-- 1. All user tables with temporal/history linkage and approximate row counts
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    hs.name AS history_schema,
    ht.name AS history_table,
    t.is_tracked_by_cdc,
    SUM(p.rows) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, hs.name, ht.name, t.is_tracked_by_cdc
ORDER BY s.name, t.name;

-- 2. Columns across the database whose names suggest personal data
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
   OR c.name LIKE '%user%'
   OR c.name LIKE '%contact%'
   OR c.name LIKE '%addr%'
ORDER BY s.name, t.name, c.column_id;

-- 3. Non-table objects that may copy data: views, procedures, functions, triggers
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    OBJECT_DEFINITION(o.object_id) AS definition_text
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('V', 'P', 'FN', 'IF', 'TF', 'TR')
ORDER BY s.name, o.name;

-- 4. Schemas present (e.g. cdc, audit, staging, archive)
SELECT s.name AS schema_name, s.schema_id
FROM sys.schemas s
ORDER BY s.name;

-- 5. Whether the temporal history table for dbo.customer exists and its columns
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.object_id IN (
    SELECT history_table_id FROM sys.tables
    WHERE schema_id = SCHEMA_ID('dbo') AND name = 'customer'
)
ORDER BY c.column_id;
