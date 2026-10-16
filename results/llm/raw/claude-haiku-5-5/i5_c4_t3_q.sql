SET NOCOUNT ON;

-- 1. All user tables with row counts and temporal/CDC/memory-optimized flags
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.history_table_id,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.is_ms_shipped,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, t.is_memory_optimized, t.is_ms_shipped
ORDER BY s.name, t.name;

-- 2. All columns in user tables, flagging character/personal-looking columns
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    CASE WHEN c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
           OR c.name LIKE '%addr%' OR c.name LIKE '%customer%' OR c.name LIKE '%subject%'
           OR c.name LIKE '%person%' OR c.name LIKE '%user%' OR c.name LIKE '%id%'
         THEN 1 ELSE 0 END AS possibly_personal
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys (to find dependent tables that may copy customer_id)
SELECT
    OBJECT_SCHEMA_NAME(f.parent_object_id) AS child_schema,
    OBJECT_NAME(f.parent_object_id) AS child_table,
    f.name AS fk_name,
    OBJECT_SCHEMA_NAME(f.referenced_object_id) AS parent_schema,
    OBJECT_NAME(f.referenced_object_id) AS parent_table,
    f.delete_referential_action_desc
FROM sys.foreign_keys f
ORDER BY child_table, fk_name;

-- 4. Views, procedures, triggers, and functions (may store or copy personal data)
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('V','P','TR','FN','IF','TF')
ORDER BY o.type_desc, s.name, o.name;

-- 5. Full-text indexes (catalog entries can retain indexed text until repopulated)
SELECT
    OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
    OBJECT_NAME(fi.object_id) AS table_name,
    fi.is_enabled
FROM sys.fulltext_indexes fi;

-- 6. Change data capture tables and capture instances
SELECT
    OBJECT_SCHEMA_NAME(ct.object_id) AS source_schema,
    OBJECT_NAME(ct.object_id) AS source_table,
    ct.capture_instance,
    ct.supports_net_changes,
    ct.create_date
FROM cdc.change_tables ct;

-- 7. Query Store presence (plan text can contain literal values)
SELECT name, is_query_store_on
FROM sys.databases
WHERE name = DB_NAME();
