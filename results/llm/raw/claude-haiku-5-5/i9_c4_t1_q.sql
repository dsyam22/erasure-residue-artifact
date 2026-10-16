SET NOCOUNT ON;

-- 1. All user tables: temporal/history linkage, CDC/change tracking flags, approximate row counts
SELECT
    s.name                         AS schema_name,
    t.name                         AS table_name,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id)        AS history_table,
    SUM(p.rows)                    AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, t.history_table_id
ORDER BY s.name, t.name;

-- 2. All columns of all user tables with data types
SELECT
    s.name  AS schema_name,
    t.name  AS table_name,
    c.name  AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t  ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name, c.column_id;

-- 3. Columns that could plausibly hold the subject's identifiers or personal data
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type
FROM sys.columns c
JOIN sys.tables t  ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE c.name LIKE '%customer%'
   OR c.name LIKE '%cust%'
   OR c.name LIKE '%name%'
   OR c.name LIKE '%email%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%mobile%'
   OR c.name LIKE '%address%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
   OR c.name LIKE '%user%'
ORDER BY s.name, t.name, c.column_id;

-- 4. Views, procedures, and functions that reference customer data (may cache or expose it)
SELECT
    o.type_desc,
    s.name AS schema_name,
    o.name AS object_name
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('V','P','FN','IF','TF')
  AND o.is_ms_shipped = 0
ORDER BY s.name, o.name;

-- 5. Text search in module definitions for the subject's identifiers
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o  ON o.object_id = m.object_id
JOIN sys.schemas s  ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%subject42%'
   OR m.definition LIKE '%Subject_0000042%'
   OR m.definition LIKE '%555-0000042%'
   OR m.definition LIKE '%customer_id = 42%'
   OR m.definition LIKE '%customer_id=42%'
ORDER BY s.name, o.name;
