SET NOCOUNT ON;

-- 1. Tables with temporal (system-versioned) settings, including history tables
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.history_table_id,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_ledger_table,
    t.is_memory_optimized
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.temporal_type <> 0 OR t.history_table_id IS NOT NULL
ORDER BY s.name, t.name;

-- 2. Columns across the database that could hold personal data
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    t.temporal_type_desc
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.tables AS t2 ON 1 = 0
WHERE c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%cust%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
   OR c.name LIKE '%user%'
ORDER BY s.name, t.name, c.column_id;

-- 3. Row counts per table (to see which tables actually contain data)
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(ps.row_count) AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.dm_db_partition_stats AS ps
    ON ps.object_id = t.object_id AND ps.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- 4. Foreign keys referencing or referenced by dbo.customer
SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    fk.delete_referential_action_desc
FROM sys.foreign_keys AS fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id = OBJECT_ID(N'dbo.customer');

-- 5. Change data capture and change tracking status
SELECT
    DB_NAME() AS database_name,
    d.is_cdc_enabled,
    d.is_change_tracking_enabled
FROM sys.databases AS d
WHERE d.name = DB_NAME();

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.is_tracked_by_cdc
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_tracked_by_cdc = 1
   OR s.name = N'cdc';
