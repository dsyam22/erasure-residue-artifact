-- Read-only inspection of llm_i9 for possible residual copies of erased personal data
SET NOCOUNT ON;

-- 1. All user tables with temporal, CDC, change tracking and row-count info
SELECT
    s.name  AS schema_name,
    t.name  AS table_name,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id)        AS history_table,
    t.is_tracked_by_cdc,
    CASE WHEN ctt.object_id IS NULL THEN 0 ELSE 1 END AS change_tracking_enabled,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ctt ON ctt.object_id = t.object_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, ctt.object_id
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal data (by name or type), across all tables
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length
FROM sys.columns c
JOIN sys.tables t  ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty  ON ty.user_type_id = c.user_type_id
WHERE c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
   OR c.name LIKE '%contact%'
   OR c.name LIKE '%address%'
   OR c.name LIKE '%note%'
   OR c.name LIKE '%json%'
   OR c.name LIKE '%payload%'
   OR c.name LIKE '%log%'
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys that reference or are referenced by dbo.customer
SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id)        AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id)    AS parent_table,
    fk.name AS fk_name
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id     = OBJECT_ID(N'dbo.customer');

-- 4. Stored procedures, views, functions, triggers that mention customer or the subject's values
SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id)        AS object_name,
    o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%subject42%'
   OR m.definition LIKE '%Subject_0000042%'
   OR m.definition LIKE '%555-0000042%';

-- 5. Search for the literal erased values in character/XML/JSON-capable columns of user tables
--    (returns only the table/column pairs to examine; no values are echoed)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.columns c
JOIN sys.tables t  ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty  ON ty.user_type_id = c.user_type_id
WHERE ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char', N'ntext', N'text', N'xml', N'sysname')
ORDER BY s.name, t.name, c.column_id;
