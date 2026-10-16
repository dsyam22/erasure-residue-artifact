SET NOCOUNT ON;

-- 1. All user tables with temporal, history, CDC and change-tracking settings
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       t.is_ms_shipped,
       t.lob_data_space_id,
       ct.object_id AS change_tracking_enabled_flag
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
ORDER BY s.name, t.name;

-- 2. Every column that could hold personal data (names, emails, phones, customer/member keys, text/LOB types)
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
WHERE c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%member%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%contact%'
   OR ty.name IN ('text', 'ntext', 'image', 'xml', 'sql_variant', 'varchar', 'nvarchar', 'char', 'nchar')
   OR ty.name IN ('varchar', 'nvarchar') AND c.max_length = -1
ORDER BY s.name, t.name, c.column_id;

-- 3. Row counts per table (from partition metadata, no table scans)
SELECT s.name AS schema_name,
       t.name AS table_name,
       SUM(ps.row_count) AS approx_row_count
FROM sys.dm_db_partition_stats AS ps
JOIN sys.tables AS t ON t.object_id = ps.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE ps.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- 4. Triggers, views and procedures that may copy or log data
SELECT o.type_desc,
       s.name AS schema_name,
       o.name AS object_name
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('TR', 'V', 'P', 'FN', 'IF', 'TF')
  AND o.is_ms_shipped = 0
ORDER BY o.type_desc, s.name, o.name;

-- 5. Full-text catalogs and indexes, which keep their own copies of indexed text
SELECT OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
       OBJECT_NAME(fti.object_id) AS table_name,
       fti.is_enabled,
       fc.name AS fulltext_catalog
FROM sys.fulltext_indexes AS fti
LEFT JOIN sys.fulltext_catalogs AS fc ON fc.fulltext_catalog_id = fti.fulltext_catalog_id;

-- 6. Non-clustered indexes on personal-data columns (index keys can retain old values until rebuilt)
SELECT OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
       OBJECT_NAME(i.object_id) AS table_name,
       i.name AS index_name,
       i.type_desc,
       c.name AS column_name
FROM sys.indexes AS i
JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id IN (SELECT object_id FROM sys.tables WHERE is_ms_shipped = 0)
  AND (c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%' OR c.name LIKE '%customer%' OR c.name LIKE '%member%')
ORDER BY schema_name, table_name, index_name;
