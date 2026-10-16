-- Read-only inventory of where personal data for customer_id 42 could still reside.

-- 1. All user tables, with temporal (history) and CDC/Change Tracking status
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       CASE WHEN ct.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
       t.is_memory_optimized,
       t.is_filetable
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal identifiers or free text (candidates for leftover data)
SELECT s.name AS schema_name,
       o.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length,
       o.type_desc
FROM sys.columns AS c
JOIN sys.objects AS o ON o.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U', 'V')
  AND (c.name LIKE '%cust%'
       OR c.name LIKE '%name%'
       OR c.name LIKE '%mail%'
       OR c.name LIKE '%phone%'
       OR c.name LIKE '%tel%'
       OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%'
       OR c.name LIKE '%user%'
       OR c.name LIKE '%contact%'
       OR ty.name IN ('xml', 'ntext', 'text', 'nvarchar', 'varchar', 'json')
       OR c.max_length = -1)
ORDER BY s.name, o.name, c.column_id;

-- 3. Foreign keys that reference or are referenced by dbo.customer
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) AS parent_schema,
       OBJECT_NAME(fk.parent_object_id) AS parent_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
       OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
       fk.delete_referential_action_desc,
       fk.update_referential_action_desc
FROM sys.foreign_keys AS fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id = OBJECT_ID(N'dbo.customer');

-- 4. Row counts per user table (heap or clustered index only)
SELECT s.name AS schema_name,
       t.name AS table_name,
       SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- 5. Database-level settings relevant to retention of deleted data
SELECT d.name AS database_name,
       d.is_cdc_enabled,
       d.is_read_committed_snapshot_on,
       d.recovery_model_desc,
       d.is_auto_close_on,
       d.is_temporal_history_retention_enabled
FROM sys.databases AS d
WHERE d.name = DB_NAME();
