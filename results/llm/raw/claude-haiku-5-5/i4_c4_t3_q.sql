SET NOCOUNT ON;

-- 1) All user tables: schema, row estimate, temporal/history/CDC/change-tracking status
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
       SUM(p.rows) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
LEFT JOIN sys.change_tracking_tables ctt ON ctt.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id, t.is_tracked_by_cdc, ctt.object_id
ORDER BY s.name, t.name;

-- 2) Character columns whose names suggest personal data, across all tables
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND (ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','json')
       OR c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%cust%' OR c.name LIKE '%member%' OR c.name LIKE '%contact%'
       OR c.name LIKE '%addr%' OR c.name LIKE '%note%' OR c.name LIKE '%log%')
ORDER BY s.name, t.name, c.column_id;

-- 3) Foreign keys touching dbo.customer or dbo.member (copies may be linked by key)
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS referencing_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS referenced_table
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.parent_object_id) IN ('customer','member')
   OR OBJECT_NAME(fk.referenced_object_id) IN ('customer','member');

-- 4) Triggers on user tables (may copy data into audit tables)
SELECT OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
       OBJECT_NAME(tr.parent_id) AS table_name,
       tr.name AS trigger_name,
       tr.is_disabled
FROM sys.triggers tr
WHERE tr.is_ms_shipped = 0;

-- 5) Modules (views, procs, functions, triggers) whose definitions reference customer/member or PII terms
SELECT OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
       OBJECT_NAME(m.object_id) AS object_name,
       o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%member%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%full_name%';

-- 6) Database-level encryption/auditing hints and Query Store presence
SELECT d.name AS database_name,
       d.is_encrypted,
       d.is_query_store_on,
       d.is_cdc_enabled
FROM sys.databases d
WHERE d.name = DB_NAME();
