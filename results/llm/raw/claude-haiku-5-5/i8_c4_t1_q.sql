SET NOCOUNT ON;

-- 1. User tables with row counts, temporal/CDC/change-tracking flags
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.history_retention_period,
    t.is_tracked_by_cdc,
    CAST(ct.object_id AS bit) AS has_change_tracking,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
LEFT JOIN sys.partitions AS p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc,
         t.history_retention_period, t.is_tracked_by_cdc, ct.object_id
ORDER BY s.name, t.name;

-- 2. Columns in any user table that could plausibly hold personal data
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
WHERE t.is_ms_shipped = 0
  AND (
        c.name LIKE '%name%'
     OR c.name LIKE '%mail%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%customer%'
     OR c.name LIKE '%subject%'
     OR c.name LIKE '%person%'
     OR c.name LIKE '%contact%'
     OR c.name LIKE '%addr%'
     OR c.name LIKE '%note%'
     OR c.name LIKE '%comment%'
     OR c.name LIKE '%json%'
     OR c.name LIKE '%xml%'
     OR ty.name IN ('xml','text','ntext','sql_variant')
  )
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys referencing dbo.customer (child tables may hold copies)
SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id)        AS child_table,
    fk.name                                 AS fk_name,
    fk.delete_referential_action_desc       AS on_delete
FROM sys.foreign_keys AS fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer');

-- 4. Views, procedures, triggers, and functions that reference customer data
SELECT
    o.type_desc,
    OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
    o.name AS object_name
FROM sys.objects AS o
WHERE o.is_ms_shipped = 0
  AND o.type IN ('V','P','TR','FN','IF','TF')
  AND OBJECT_DEFINITION(o.object_id) LIKE '%customer%'
ORDER BY o.type_desc, o.name;

-- 5. Full-text indexes and LOB-bearing columns (possible stale copies)
SELECT
    OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
    OBJECT_NAME(fi.object_id)        AS table_name,
    fi.is_enabled
FROM sys.fulltext_indexes AS fi;

-- 6. Database-level settings relevant to retention
SELECT
    d.name,
    d.recovery_model_desc,
    d.is_change_data_capture_enabled,
    d.is_temporal_history_retention_enabled
FROM sys.databases AS d
WHERE d.name = DB_NAME();
