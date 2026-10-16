SET NOCOUNT ON;

-- 1. All user tables with row counts, temporal/CDC/change-tracking status
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.history_retention_period,
    t.is_tracked_by_cdc,
    CASE WHEN ct.object_id IS NOT NULL THEN 1 ELSE 0 END AS is_change_tracked,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_retention_period,
         t.is_tracked_by_cdc, ct.object_id
ORDER BY s.name, t.name;

-- 2. All columns that could hold personal data (by name or by string/LOB type)
SELECT
    s.name AS schema_name,
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
  AND (
        ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sql_variant')
     OR c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
     OR c.name LIKE '%cust%' OR c.name LIKE '%member%' OR c.name LIKE '%subject%'
     OR c.name LIKE '%person%' OR c.name LIKE '%contact%'
      )
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys that point at customer or member (possible copies of the identifier)
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.referenced_object_id) IN ('customer','member')
   OR OBJECT_NAME(fk.parent_object_id) IN ('customer','member');

-- 4. Triggers and modules whose definitions mention the relevant tables or PII fields
SELECT
    o.type_desc,
    OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
    o.name AS object_name
FROM sys.objects o
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND (m.definition LIKE '%customer%' OR m.definition LIKE '%member%'
       OR m.definition LIKE '%email%' OR m.definition LIKE '%phone%'
       OR m.definition LIKE '%full_name%');

-- 5. Audit / CDC / history-like tables by name
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND (t.name LIKE '%audit%' OR t.name LIKE '%hist%' OR t.name LIKE '%log%'
       OR t.name LIKE '%cdc%' OR t.name LIKE '%backup%' OR t.name LIKE '%archive%'
       OR t.name LIKE '%staging%' OR t.name LIKE '%temp%' OR t.name LIKE '%export%');

-- 6. Full-text indexes, which can retain copies of text in index structures
SELECT OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
       OBJECT_NAME(fti.object_id) AS table_name
FROM sys.fulltext_indexes fti;

-- 7. Database-level settings relevant to retained data
SELECT name, is_auto_close_on, is_auto_shrink_on, recovery_model_desc,
       is_change_data_capture_enabled, is_temporal_history_retention_enabled
FROM sys.databases
WHERE name = DB_NAME();
