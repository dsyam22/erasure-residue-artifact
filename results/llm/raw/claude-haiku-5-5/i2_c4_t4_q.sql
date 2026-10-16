-- Read-only inventory for residual personal data checks (llm_i2, SQL Server 2022)
SET NOCOUNT ON;

-- 1. All user tables with temporal / CDC / change-tracking status
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       hs.name + '.' + ht.name AS history_table,
       t.is_tracked_by_cdc,
       CASE WHEN ct.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
       p.rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
LEFT JOIN (SELECT object_id, SUM(row_count) AS rows
           FROM sys.dm_db_partition_stats
           WHERE index_id IN (0,1)
           GROUP BY object_id) p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal data (by type or name), across all user tables
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND (
        TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sql_variant','varbinary','binary','image')
        OR c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
        OR c.name LIKE '%customer%' OR c.name LIKE '%subject%' OR c.name LIKE '%user%'
        OR c.name LIKE '%contact%' OR c.name LIKE '%address%' OR c.name LIKE '%ip%'
      )
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys referencing dbo.customer (child tables that may keep copies or IDs)
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID('dbo.customer');

-- 4. Views, procedures, functions, triggers that reference customer or look like audit/log objects
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND (
        o.type IN ('V','P','FN','IF','TF','TR')
        AND OBJECT_DEFINITION(o.object_id) LIKE '%customer%'
        OR o.name LIKE '%audit%' OR o.name LIKE '%log%' OR o.name LIKE '%hist%'
        OR o.name LIKE '%backup%' OR o.name LIKE '%archive%' OR o.name LIKE '%staging%'
      )
ORDER BY s.name, o.name;

-- 5. Non-dbo schemas and temporal/history tables that may be easy to miss
SELECT sc.name AS schema_name, COUNT(*) AS table_count
FROM sys.tables tb
JOIN sys.schemas sc ON sc.schema_id = tb.schema_id
WHERE tb.is_ms_shipped = 0
GROUP BY sc.name
ORDER BY sc.name;
