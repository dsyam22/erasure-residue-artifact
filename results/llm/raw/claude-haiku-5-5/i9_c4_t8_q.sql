SET NOCOUNT ON;

-- 1. Tables and their temporal / CDC / ledger status
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    t.ledger_type_desc,
    t.is_memory_optimized
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name;

-- 2. Columns that could hold the subject's identifiers or personal data
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
WHERE c.name LIKE '%customer%'
   OR c.name LIKE '%cust%'
   OR c.name LIKE '%name%'
   OR c.name LIKE '%email%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
   OR c.name LIKE '%user%'
   OR c.name LIKE '%address%'
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys that reference dbo.customer (child tables may keep copies)
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    fk.delete_referential_action_desc
FROM sys.foreign_keys AS fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer');

-- 4. Row counts per table (approximate, from partition metadata)
SELECT
    OBJECT_SCHEMA_NAME(p.object_id) AS schema_name,
    OBJECT_NAME(p.object_id) AS table_name,
    SUM(p.rows) AS approx_rows
FROM sys.partitions AS p
WHERE p.index_id IN (0, 1)
GROUP BY p.object_id
ORDER BY schema_name, table_name;

-- 5. Change Tracking status for the database and tables
SELECT
    DB_NAME() AS database_name,
    ctd.is_auto_cleanup_on,
    ctd.retention_period,
    OBJECT_SCHEMA_NAME(ctt.object_id) AS ct_schema,
    OBJECT_NAME(ctt.object_id) AS ct_table
FROM sys.change_tracking_databases AS ctd
LEFT JOIN sys.change_tracking_tables AS ctt ON ctt.database_id = ctd.database_id
WHERE ctd.database_id = DB_ID();
