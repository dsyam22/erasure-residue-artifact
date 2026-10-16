SET NOCOUNT ON;

-- 1. User tables with row counts and history/tracking features
SELECT
    s.name                       AS schema_name,
    t.name                       AS table_name,
    t.is_ms_shipped,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s            ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p    ON p.object_id = t.object_id
LEFT JOIN sys.change_tracking_tables ctt ON ctt.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.is_ms_shipped, t.temporal_type_desc,
         t.is_tracked_by_cdc, CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END
ORDER BY s.name, t.name;

-- 2. Character/LOB columns in user tables (candidates for holding personal data)
SELECT
    s.name      AS schema_name,
    t.name      AS table_name,
    c.name      AS column_name,
    ty.name     AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables  t  ON t.object_id = c.object_id
JOIN sys.schemas s  ON s.schema_id = t.schema_id
JOIN sys.types   ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
ORDER BY s.name, t.name, c.column_id;

-- 3. Triggers, views, procedures and functions that might copy or log data
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    o.create_date,
    o.modify_date
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('TR','V','P','FN','IF','TF')
ORDER BY o.type_desc, s.name, o.name;

-- 4. Full-text indexes and any tables referencing dbo.customer via foreign keys
SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id)        AS child_table,
    fk.name                                 AS fk_name,
    OBJECT_NAME(fk.referenced_object_id)    AS parent_table
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id     = OBJECT_ID(N'dbo.customer');

SELECT
    OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
    OBJECT_NAME(fti.object_id)        AS table_name,
    fti.is_enabled
FROM sys.fulltext_indexes fti;
