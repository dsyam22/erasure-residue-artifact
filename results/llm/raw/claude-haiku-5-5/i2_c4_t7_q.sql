SET NOCOUNT ON;

-- 1. Database-level context: temporal/CDC/change-tracking settings
SELECT 'database' AS info_type,
       DB_NAME() AS database_name,
       (SELECT is_cdc_enabled FROM sys.databases WHERE name = DB_NAME()) AS cdc_enabled,
       (SELECT CAST(COUNT(*) AS int) FROM sys.change_tracking_databases WHERE database_id = DB_ID()) AS change_tracking_enabled;

-- 2. All user tables with temporal, CDC, and change-tracking status, plus approximate row counts
SELECT 'table' AS info_type,
       SCHEMA_NAME(t.schema_id) AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       t.is_tracked_by_cdc AS cdc_flag_dup,
       ct.object_id AS change_tracked_object_id,
       SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS approx_rows
FROM sys.tables AS t
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
LEFT JOIN sys.dm_db_partition_stats AS ps ON ps.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY t.schema_id, t.name, t.temporal_type_desc, t.history_table_id,
         t.is_tracked_by_cdc, ct.object_id
ORDER BY schema_name, table_name;

-- 3. Columns that could hold personal data (by name) or are free-form text/binary/XML/JSON
SELECT 'column' AS info_type,
       SCHEMA_NAME(t.schema_id) AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
WHERE t.is_ms_shipped = 0
  AND (
        c.name LIKE '%name%'
     OR c.name LIKE '%mail%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%tel%'
     OR c.name LIKE '%cust%'
     OR c.name LIKE '%subject%'
     OR c.name LIKE '%person%'
     OR c.name LIKE '%user%'
     OR c.name LIKE '%contact%'
     OR c.name LIKE '%addr%'
     OR c.name LIKE '%note%'
     OR c.name LIKE '%comment%'
     OR c.name LIKE '%json%'
     OR c.name LIKE '%xml%'
     OR TYPE_NAME(c.user_type_id) IN ('xml','text','ntext','image','sql_variant')
     OR (TYPE_NAME(c.user_type_id) IN ('varchar','nvarchar','char','nchar') AND (c.max_length = -1 OR c.max_length > 255))
      )
ORDER BY schema_name, table_name, column_name;

-- 4. Foreign keys referencing dbo.customer (to find dependent copies)
SELECT 'fk_to_customer' AS info_type,
       SCHEMA_NAME(fk.schema_id) AS referencing_schema,
       OBJECT_NAME(fk.parent_object_id) AS referencing_table,
       fk.name AS fk_name,
       fk.delete_referential_action_desc
FROM sys.foreign_keys AS fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer');

-- 5. Views, procedures, triggers, and functions whose definitions mention customer PII terms
SELECT 'module_reference' AS info_type,
       SCHEMA_NAME(o.schema_id) AS schema_name,
       o.name AS object_name,
       o.type_desc,
       CASE WHEN m.definition LIKE '%customer%' THEN 1 ELSE 0 END AS mentions_customer,
       CASE WHEN m.definition LIKE '%email%' OR m.definition LIKE '%phone%' THEN 1 ELSE 0 END AS mentions_contact_fields
FROM sys.objects AS o
JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
ORDER BY schema_name, object_name;

-- 6. Full-text indexes (may hold copies of text not visible in base tables)
SELECT 'fulltext_index' AS info_type,
       SCHEMA_NAME(t.schema_id) AS schema_name,
       t.name AS table_name
FROM sys.fulltext_indexes AS fi
JOIN sys.tables AS t ON t.object_id = fi.object_id;
