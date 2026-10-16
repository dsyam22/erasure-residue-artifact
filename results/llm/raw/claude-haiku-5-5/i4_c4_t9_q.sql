SET NOCOUNT ON;

-- 1) All user tables: temporal/CDC/row-count context
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    t.is_ms_shipped,
    SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, t.history_table_id, t.is_tracked_by_cdc, t.is_ms_shipped
ORDER BY s.name, t.name;

-- 2) Columns that could hold personal data (by name pattern) across all user tables, views included
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND (
        c.name LIKE '%name%'
     OR c.name LIKE '%mail%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%tel%'
     OR c.name LIKE '%cust%'
     OR c.name LIKE '%member%'
     OR c.name LIKE '%subject%'
     OR c.name LIKE '%person%'
     OR c.name LIKE '%addr%'
     OR c.name LIKE '%ip%'
     OR c.name LIKE '%note%'
     OR c.name LIKE '%comment%'
     OR c.name LIKE '%json%'
     OR c.name LIKE '%xml%'
      )
ORDER BY s.name, o.name, c.column_id;

-- 3) Foreign keys referencing dbo.customer or dbo.member (dependents may hold copies)
SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    fk.name AS fk_name
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.referenced_object_id) IN (N'customer', N'member');

-- 4) Views, procedures, triggers, and functions whose definitions mention the affected names
SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id) AS object_name,
    o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE N'%customer%'
   OR m.definition LIKE N'%member%'
   OR m.definition LIKE N'%email%'
   OR m.definition LIKE N'%phone%';

-- 5) Full-text indexes and change tracking (these can retain copies outside base tables)
SELECT OBJECT_SCHEMA_NAME(object_id) AS schema_name, OBJECT_NAME(object_id) AS table_name
FROM sys.fulltext_indexes;

SELECT OBJECT_SCHEMA_NAME(object_id) AS schema_name, OBJECT_NAME(object_id) AS table_name
FROM sys.change_tracking_tables;

-- 6) Triggers on user tables
SELECT
    OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
    OBJECT_NAME(tr.parent_id) AS table_name,
    tr.name AS trigger_name,
    tr.is_disabled
FROM sys.triggers tr
WHERE tr.is_ms_shipped = 0;

-- 7) Schemas present (e.g., a cdc, audit, or archive schema)
SELECT s.name AS schema_name, s.schema_id
FROM sys.schemas s
WHERE s.schema_id BETWEEN 5 AND 16383
ORDER BY s.name;
