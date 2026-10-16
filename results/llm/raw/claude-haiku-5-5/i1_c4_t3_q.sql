-- Read-only inspection batch: SELECT statements only.
SET NOCOUNT ON;

-- 1. Basic database context
SELECT DB_NAME() AS database_name,
       @@VERSION AS sql_server_version,
       SYSDATETIMEOFFSET() AS checked_at;

-- 2. All user tables with approximate row counts
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.is_memory_optimized,
       t.temporal_type_desc,
       t.is_tracked_by_cdc,
       t.is_ms_shipped,
       SUM(p.rows) AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.is_memory_optimized, t.temporal_type_desc, t.is_tracked_by_cdc, t.is_ms_shipped
ORDER BY s.name, t.name;

-- 3. Character/LOB columns that could hold names, emails, phones (or free text containing them)
SELECT s.name AS schema_name,
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
  AND (ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
       OR c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%cust%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%')
ORDER BY s.name, t.name, c.column_id;

-- 4. Columns named like the customer key (possible copies keyed by customer_id)
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND c.name LIKE '%customer%'
ORDER BY s.name, t.name;

-- 5. Temporal history tables (may retain deleted rows)
SELECT s.name AS schema_name,
       t.name AS table_name,
       h.name AS history_table_schema_and_name_source,
       hs.name AS history_schema,
       h.name  AS history_table
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS h ON h.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = h.schema_id
WHERE t.temporal_type = 2;

-- 6. Foreign keys referencing or referenced by dbo.customer
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
       OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
       OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc
FROM sys.foreign_keys AS fk
WHERE OBJECT_NAME(fk.referenced_object_id) = 'customer'
   OR OBJECT_NAME(fk.parent_object_id) = 'customer';

-- 7. Change Data Capture and Change Tracking status
SELECT OBJECT_SCHEMA_NAME(ct.object_id) AS schema_name,
       OBJECT_NAME(ct.object_id) AS table_name,
       ct.begin_lsn, ct.is_track_columns_updated_on
FROM cdc.change_tables AS ct;

SELECT OBJECT_SCHEMA_NAME(ctt.object_id) AS schema_name,
       OBJECT_NAME(ctt.object_id) AS table_name
FROM sys.change_tracking_tables AS ctt;

-- 8. Triggers on any user table (may copy data to audit tables)
SELECT OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
       OBJECT_NAME(tr.parent_id) AS table_name,
       tr.name AS trigger_name,
       tr.is_disabled
FROM sys.triggers AS tr
WHERE tr.is_ms_shipped = 0;

-- 9. Views, procedures, functions whose definitions mention customer or the subject
SELECT OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
       OBJECT_NAME(m.object_id) AS object_name,
       o.type_desc
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%Subject_0000042%'
   OR m.definition LIKE '%subject42%';

-- 10. Full-text, service broker queues, and Query Store presence (possible residual copies)
SELECT name AS catalog_name, is_default FROM sys.fulltext_catalogs;
SELECT name AS queue_name FROM sys.service_queues WHERE is_ms_shipped = 0;
SELECT actual_state_desc, desired_state_desc FROM sys.database_query_store_options;
