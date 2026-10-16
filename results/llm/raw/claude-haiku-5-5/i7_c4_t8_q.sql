USE llm_i7;

-- 1. All user tables with row counts and history/CDC/temporal flags
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.is_tracked_by_cdc,
       t.is_ms_shipped,
       SUM(p.rows) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, t.is_ms_shipped
ORDER BY s.name, t.name;

-- 2. Columns that could hold personal data (by name or type), across all tables and views
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('U','V')
  AND (c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%customer%' OR c.name LIKE '%cust%' OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%' OR c.name LIKE '%contact%' OR c.name LIKE '%user%'
       OR c.name LIKE '%addr%' OR c.name LIKE '%note%' OR c.name LIKE '%comment%'
       OR c.name LIKE '%json%' OR c.name LIKE '%payload%' OR c.name LIKE '%log%')
ORDER BY s.name, o.name, c.column_id;

-- 3. Temporal history tables and their parent tables
SELECT s.name AS schema_name, t.name AS table_name,
       h.name AS history_schema, ht.name AS history_table
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas h ON h.schema_id = ht.schema_id
WHERE t.temporal_type = 2;

-- 4. CDC capture instances and change tracking tables
SELECT ct.capture_instance, s.name AS source_schema, o.name AS source_table,
       ct.index_name, ct.supports_net_changes
FROM cdc.change_tables ct
JOIN sys.objects o ON o.object_id = ct.source_object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id;

SELECT s.name AS schema_name, t.name AS table_name
FROM sys.change_tracking_tables ctt
JOIN sys.tables t ON t.object_id = ctt.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id;

-- 5. Triggers (may copy rows into audit or log tables)
SELECT s.name AS schema_name, o.name AS parent_table, tr.name AS trigger_name,
       tr.is_disabled, OBJECT_DEFINITION(tr.object_id) AS trigger_definition
FROM sys.triggers tr
JOIN sys.objects o ON o.object_id = tr.parent_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE tr.is_ms_shipped = 0;

-- 6. Views and procedures whose definitions reference the customer tables
SELECT s.name AS schema_name, o.name AS object_name, o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%';

-- 7. Foreign keys referencing dbo.customer or reporting.customer_replica
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('reporting.customer_replica'));

-- 8. Full-text indexes and columns covered (text search may retain copies)
SELECT OBJECT_SCHEMA_NAME(fti.object_id) AS schema_name,
       OBJECT_NAME(fti.object_id) AS table_name
FROM sys.fulltext_indexes fti;
