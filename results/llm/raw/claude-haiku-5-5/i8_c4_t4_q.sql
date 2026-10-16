-- 1. Database context and version
SELECT DB_NAME() AS database_name, @@VERSION AS server_version;

-- 2. All user tables with approximate row counts and special-feature flags
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.is_tracked_by_cdc,
       t.is_memory_optimized,
       SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, t.is_memory_optimized
ORDER BY s.name, t.name;

-- 3. All columns with data types, flagging likely personal-data columns
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length,
       CASE WHEN c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
              OR c.name LIKE '%tel%' OR c.name LIKE '%addr%' OR c.name LIKE '%ssn%'
              OR c.name LIKE '%cust%' OR c.name LIKE '%user%' OR c.name LIKE '%person%'
              OR c.name LIKE '%note%' OR c.name LIKE '%comment%' OR c.name LIKE '%json%'
              OR c.name LIKE '%text%' OR c.name LIKE '%desc%'
            THEN 1 ELSE 0 END AS possible_personal_data
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY possible_personal_data DESC, s.name, t.name, c.column_id;

-- 4. Foreign keys referencing dbo.customer (child tables may hold copies of the key or data)
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer');

-- 5. Tables with temporal history, plus change tracking status
SELECT OBJECT_SCHEMA_NAME(t.object_id) + '.' + OBJECT_NAME(t.object_id) AS table_name,
       OBJECT_SCHEMA_NAME(t.history_table_id) + '.' + OBJECT_NAME(t.history_table_id) AS history_table
FROM sys.tables t
WHERE t.history_table_id IS NOT NULL;

SELECT OBJECT_SCHEMA_NAME(ctt.object_id) + '.' + OBJECT_NAME(ctt.object_id) AS change_tracked_table,
       ctt.is_track_columns_updated_on
FROM sys.change_tracking_tables ctt;

-- 6. Full-text indexes, which can keep stale index entries
SELECT OBJECT_SCHEMA_NAME(fti.object_id) + '.' + OBJECT_NAME(fti.object_id) AS fulltext_table,
       fti.is_enabled
FROM sys.fulltext_indexes fti;

-- 7. Column-level and table-level usage of the erased identifiers (customer_id 42)
--    Checks the customer table itself for any remaining row with the subject's values
SELECT COUNT(*) AS remaining_rows_in_customer
FROM dbo.customer
WHERE customer_id = 42
   OR full_name LIKE N'%Subject_0000042%'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
