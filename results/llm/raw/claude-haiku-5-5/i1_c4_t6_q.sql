SET NOCOUNT ON;

-- 1. All user tables with row counts and special features
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    t.is_ms_shipped,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, t.is_ms_shipped
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal data (text/LOB/xml types, or identifying names)
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
     OR c.name LIKE '%cust%'
     OR c.name LIKE '%email%'
     OR c.name LIKE '%mail%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%name%'
     OR c.name LIKE '%subject%'
     OR c.name LIKE '%person%'
     OR c.name LIKE '%user%'
  )
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys referencing or referenced by dbo.customer
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id = OBJECT_ID(N'dbo.customer');

-- 4. Temporal history tables and CDC capture instances
SELECT
    OBJECT_SCHEMA_NAME(object_id) AS schema_name,
    name AS table_name,
    history_table_id
FROM sys.tables
WHERE history_table_id IS NOT NULL;

SELECT
    capture_instance,
    source_object_id,
    OBJECT_SCHEMA_NAME(source_object_id) + '.' + OBJECT_NAME(source_object_id) AS source_table
FROM cdc.change_tables;

-- 5. Full-text indexes and change tracking (may retain text or keys)
SELECT
    OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id) AS table_name,
    is_enabled
FROM sys.fulltext_indexes;

SELECT
    OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id) AS table_name,
    is_track_columns_updated_on
FROM sys.change_tracking_tables;
