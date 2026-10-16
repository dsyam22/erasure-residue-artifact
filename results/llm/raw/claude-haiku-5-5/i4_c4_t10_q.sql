SET NOCOUNT ON;

-- 1. Candidate PII columns across the whole database
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%addr%'
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%member%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
ORDER BY s.name, t.name, c.column_id;

-- 2. All user tables with row counts and temporal / history configuration
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    t.is_ms_shipped,
    SUM(p.rows) AS approx_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, t.is_ms_shipped
ORDER BY s.name, t.name;

-- 3. Change tracking and CDC state (these can retain old values)
SELECT
    DB_NAME() AS database_name,
    (SELECT COUNT(*) FROM sys.change_tracking_tables) AS change_tracked_tables,
    (SELECT is_cdc_enabled FROM sys.databases WHERE name = DB_NAME()) AS cdc_enabled,
    (SELECT COUNT(*) FROM sys.triggers WHERE is_ms_shipped = 0) AS user_triggers;

-- 4. Trigger definitions (could copy data into audit or log tables)
SELECT
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
    OBJECT_NAME(tr.parent_id) AS parent_table,
    tr.name AS trigger_name,
    tr.is_disabled,
    OBJECT_DEFINITION(tr.object_id) AS trigger_definition
FROM sys.triggers AS tr
WHERE tr.is_ms_shipped = 0;

-- 5. Views and procedures that reference customer or member
SELECT
    o.type_desc,
    s.name AS schema_name,
    o.name AS object_name
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%member%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
ORDER BY o.type_desc, s.name, o.name;

-- 6. Foreign keys that point at dbo.customer or dbo.member (copies of IDs)
SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    fk.name AS fk_name
FROM sys.foreign_keys AS fk
WHERE OBJECT_NAME(fk.referenced_object_id) IN (N'customer', N'member');
