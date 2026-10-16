SET NOCOUNT ON;

-- 1. Database context and version
SELECT DB_NAME() AS database_name,
       @@VERSION AS sql_version,
       SYSDATETIME() AS inspected_at;

-- 2. All user tables with row counts, temporal/ledger/CDC/change-tracking flags
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       t.temporal_type_desc,
       t.is_ledger_table,
       t.is_tracked_by_cdc,
       CASE WHEN ctt.object_id IS NULL THEN 0 ELSE 1 END AS change_tracking_enabled,
       t.history_retention_period,
       SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ctt ON ctt.object_id = t.object_id
LEFT JOIN sys.dm_db_partition_stats AS ps ON ps.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, t.is_ledger_table,
         t.is_tracked_by_cdc, ctt.object_id, t.history_retention_period
ORDER BY s.name, t.name;

-- 3. Columns that are character/LOB/XML/JSON-capable or whose names suggest personal data
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
       OR c.name LIKE '%cust%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%'
       OR c.name LIKE '%user%' OR c.name LIKE '%contact%' OR c.name LIKE '%addr%')
ORDER BY s.name, t.name, c.column_id;

-- 4. Foreign keys that reference or are referenced by dbo.customer
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys AS fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id = OBJECT_ID(N'dbo.customer');

-- 5. Views, procedures, functions, triggers whose definitions mention customer or the subject's values
SELECT o.type_desc,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name,
       CASE WHEN m.definition LIKE '%customer%' THEN 1 ELSE 0 END AS mentions_customer,
       CASE WHEN m.definition LIKE '%subject42%' OR m.definition LIKE '%Subject_0000042%'
              OR m.definition LIKE '%555-0000042%' THEN 1 ELSE 0 END AS mentions_subject_literal
FROM sys.objects AS o
JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND (m.definition LIKE '%customer%' OR m.definition LIKE '%subject42%'
       OR m.definition LIKE '%Subject_0000042%' OR m.definition LIKE '%555-0000042%')
ORDER BY o.type_desc, o.name;

-- 6. Indexes on dbo.customer (deleted keys can persist in nonclustered indexes until rebuilt/reorganized)
SELECT i.name AS index_name,
       i.type_desc,
       i.is_primary_key,
       i.is_unique,
       i.is_disabled,
       STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns
FROM sys.indexes AS i
LEFT JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0
LEFT JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.customer')
GROUP BY i.name, i.type_desc, i.is_primary_key, i.is_unique, i.is_disabled;

-- 7. Full-text indexes and columns (search catalogs can retain deleted text)
SELECT OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
       OBJECT_NAME(fti.object_id) AS table_name,
       fti.is_enabled,
       ftc.name AS column_name
FROM sys.fulltext_indexes AS fti
JOIN sys.fulltext_index_columns AS fic ON fic.object_id = fti.object_id
JOIN sys.columns AS ftc ON ftc.object_id = fic.object_id AND ftc.column_id = fic.column_id;

-- 8. Temporal history tables and CDC capture instances present
SELECT OBJECT_SCHEMA_NAME(h.object_id) AS history_schema,
       OBJECT_NAME(h.object_id) AS history_table,
       OBJECT_SCHEMA_NAME(t.object_id) AS current_schema,
       OBJECT_NAME(t.object_id) AS current_table
FROM sys.tables AS h
JOIN sys.tables AS t ON t.history_table_id = h.object_id;

SELECT capture_instance,
       OBJECT_SCHEMA_NAME(source_object_id) AS source_schema,
       OBJECT_NAME(source_object_id) AS source_table,
       create_date
FROM cdc.change_tables;
