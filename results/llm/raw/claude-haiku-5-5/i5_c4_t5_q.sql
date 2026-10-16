SET NOCOUNT ON;

-- 1. All user tables, including temporal (system-versioned) and history table info
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    t.lock_escalation_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    p.rows AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
OUTER APPLY (
    SELECT SUM(ps.row_count) AS rows
    FROM sys.dm_db_partition_stats AS ps
    WHERE ps.object_id = t.object_id AND ps.index_id IN (0, 1)
) AS p
ORDER BY s.name, t.name;

-- 2. Columns that could hold the erased subject's identifiers or personal data
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE c.name LIKE '%cust%'
   OR c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%person%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%user%'
   OR c.name LIKE '%contact%'
   OR c.name LIKE '%addr%'
   OR c.name LIKE '%log%'
   OR c.name LIKE '%audit%'
   OR TYPE_NAME(c.user_type_id) IN ('xml', 'json', 'text', 'ntext', 'varbinary', 'image')
ORDER BY s.name, t.name, c.column_id;

-- 3. Triggers and modules that reference the customer table or personal-data columns
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    o.parent_object_id,
    OBJECT_NAME(o.parent_object_id) AS parent_table
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('TR', 'V', 'P', 'FN', 'IF', 'TF')
  AND (
        OBJECT_NAME(o.parent_object_id) = 'customer'
     OR OBJECT_DEFINITION(o.object_id) LIKE '%customer%'
     OR OBJECT_DEFINITION(o.object_id) LIKE '%email%'
     OR OBJECT_DEFINITION(o.object_id) LIKE '%phone%'
      )
ORDER BY s.name, o.name;

-- 4. CDC capture instances and change tracking settings
SELECT
    OBJECT_SCHEMA_NAME(ct.object_id) AS schema_name,
    OBJECT_NAME(ct.object_id) AS table_name,
    'change_tracking' AS feature
FROM sys.change_tracking_tables AS ct
UNION ALL
SELECT
    cc.capture_instance,
    OBJECT_NAME(cc.source_object_id),
    'cdc_capture_instance'
FROM cdc.change_tables AS cc;

-- 5. Full-text indexes and whether the database has these features enabled
SELECT
    OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
    OBJECT_NAME(fi.object_id) AS table_name,
    fi.is_enabled
FROM sys.fulltext_indexes AS fi;

-- 6. Database-level context: recovery model and whether CDC/temporal features are on
SELECT
    DB_NAME() AS database_name,
    d.recovery_model_desc,
    d.is_cdc_enabled,
    d.is_change_tracking_on_db = CASE WHEN EXISTS (SELECT 1 FROM sys.change_tracking_databases WHERE database_id = DB_ID()) THEN 1 ELSE 0 END
FROM sys.databases AS d
WHERE d.database_id = DB_ID();
