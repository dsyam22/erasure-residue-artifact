SET NOCOUNT ON;

-- 1. All user tables with temporal, CDC, change tracking and row-count info
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.history_table_id,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
    SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ctt ON ctt.object_id = t.object_id
LEFT JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, ctt.object_id
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal data (character/identifier-like or the customer_id key)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND (
        TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sql_variant')
     OR c.name LIKE '%name%'
     OR c.name LIKE '%mail%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%cust%'
     OR c.name LIKE '%subject%'
     OR c.name LIKE '%person%'
      )
ORDER BY s.name, t.name, c.column_id;

-- 3. Non-table objects that may store or copy data: triggers, procedures, views, functions
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    o.parent_object_id,
    OBJECT_NAME(o.parent_object_id) AS parent_table
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('TR','P','V','FN','IF','TF')
ORDER BY s.name, o.name;

-- 4. Feature flags and auditing that may retain copies outside user tables
SELECT 'database_cdc' AS feature, CAST(is_cdc_enabled AS int) AS enabled FROM sys.databases WHERE name = DB_NAME()
UNION ALL
SELECT 'change_tracking_db', CASE WHEN EXISTS (SELECT 1 FROM sys.change_tracking_databases WHERE database_id = DB_ID()) THEN 1 ELSE 0 END
UNION ALL
SELECT 'server_audit_specs_in_db', COUNT(*) FROM sys.database_audit_specifications
UNION ALL
SELECT 'fulltext_catalogs', COUNT(*) FROM sys.fulltext_catalogs;

-- 5. Foreign keys referencing dbo.customer (child tables may hold copies of customer_id)
SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer');
