SET NOCOUNT ON;

-- 1. Database-level features that can retain copies of deleted rows
SELECT 'DB_FEATURE' AS info_type,
       name AS object_name,
       CAST(is_cdc_enabled AS int) AS flag1,
       CAST(is_change_tracking_on AS int) AS flag2,
       CAST(is_temporal_on AS int) AS flag3
FROM sys.databases
WHERE name = DB_NAME();

-- 2. All user tables with approximate row counts
SELECT 'TABLE' AS info_type,
       s.name + '.' + t.name AS object_name,
       t.temporal_type_desc AS detail1,
       CAST(t.is_tracked_by_cdc AS int) AS flag1,
       SUM(p.rows) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc
ORDER BY object_name;

-- 3. Columns that could hold identity or contact data (by name pattern and type)
SELECT 'COLUMN' AS info_type,
       s.name + '.' + t.name + '.' + c.name AS object_name,
       TYPE_NAME(c.user_type_id) AS detail1,
       c.max_length AS flag1,
       NULL AS approx_rows
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
   OR c.name LIKE '%tel%' OR c.name LIKE '%cust%' OR c.name LIKE '%subject%'
   OR c.name LIKE '%user%' OR c.name LIKE '%person%' OR c.name LIKE '%contact%'
   OR c.name LIKE '%addr%' OR c.name LIKE '%json%' OR c.name LIKE '%note%'
   OR c.name LIKE '%comment%' OR c.name LIKE '%log%' OR c.name LIKE '%payload%'
   OR TYPE_NAME(c.user_type_id) IN ('xml','text','ntext','sysname')
ORDER BY object_name;

-- 4. Foreign keys pointing at dbo.customer (child tables may hold copies or IDs)
SELECT 'FK_REF' AS info_type,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS object_name,
       fk.name AS detail1,
       fk.delete_referential_action AS flag1,
       NULL AS approx_rows
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID('dbo.customer');

-- 5. Triggers and programmable objects whose text mentions the customer data
SELECT 'MODULE' AS info_type,
       OBJECT_SCHEMA_NAME(m.object_id) + '.' + OBJECT_NAME(m.object_id) AS object_name,
       o.type_desc AS detail1,
       NULL AS flag1,
       NULL AS approx_rows
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
ORDER BY object_name;

-- 6. Full-text indexes, which keep their own copies of indexed text
SELECT 'FULLTEXT' AS info_type,
       OBJECT_SCHEMA_NAME(fti.object_id) + '.' + OBJECT_NAME(fti.object_id) AS object_name,
       fti.is_enabled AS detail1,
       NULL AS flag1,
       NULL AS approx_rows
FROM sys.fulltext_indexes fti;
