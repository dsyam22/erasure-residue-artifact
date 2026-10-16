SET NOCOUNT ON;

-- 1. All user tables with row counts and temporal/CDC/change-tracking flags
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.is_tracked_by_cdc,
       ct.object_id AS change_tracking_enabled,
       SUM(p.rows) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, ct.object_id
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal data (name, email, phone, or free text/LOB)
SELECT s.name AS schema_name,
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
        c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
     OR c.name LIKE '%cust%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%'
     OR c.name LIKE '%user%' OR c.name LIKE '%contact%' OR c.name LIKE '%id'
     OR TYPE_NAME(c.user_type_id) IN ('text','ntext','xml','json','sql_variant','image')
     OR (TYPE_NAME(c.user_type_id) IN ('varchar','nvarchar','char','nchar') AND (c.max_length = -1 OR c.max_length >= 200))
      )
ORDER BY s.name, t.name, c.column_id;

-- 3. Foreign keys referencing dbo.customer (other tables that may hold copies of the customer key)
SELECT OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
       OBJECT_NAME(fk.parent_object_id) AS child_table,
       fk.name AS fk_name
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID('dbo.customer');

-- 4. Modules (triggers, procedures, views, functions) whose definitions mention customer or PII fields
SELECT OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
       OBJECT_NAME(m.object_id) AS object_name,
       o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%full_name%';

-- 5. Full-text indexes and triggers on dbo.customer
SELECT OBJECT_NAME(fti.object_id) AS fulltext_table
FROM sys.fulltext_indexes fti
WHERE fti.object_id = OBJECT_ID('dbo.customer');

SELECT tr.name AS trigger_name,
       tr.is_disabled,
       OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
       OBJECT_NAME(tr.parent_id) AS parent_table
FROM sys.triggers tr
WHERE tr.parent_id = OBJECT_ID('dbo.customer');

-- 6. Recent backup history for this database (copies outside the live tables)
SELECT TOP (10)
       bs.backup_finish_date,
       bs.type,
       bs.backup_size,
       bmf.physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bmf.media_set_id = bs.media_set_id
WHERE bs.database_name = DB_NAME()
ORDER BY bs.backup_finish_date DESC;
