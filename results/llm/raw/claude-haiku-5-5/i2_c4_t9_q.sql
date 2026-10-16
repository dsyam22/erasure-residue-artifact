-- Read-only reconnaissance: where could erased personal data still reside?

-- 1. Basic context
SELECT DB_NAME() AS database_name,
       SERVERPROPERTY('ProductVersion') AS product_version,
       SERVERPROPERTY('Edition') AS edition;

-- 2. All user tables with schema, temporal/ledger/CDC flags, and approximate row counts
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       t.temporal_type_desc,
       t.history_retention_period,
       t.is_ledger_table,
       t.is_tracked_by_cdc,
       t.is_memory_optimized,
       hs.name AS history_schema_name,
       ht.name AS history_table_name,
       SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.dm_db_partition_stats AS ps ON ps.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.temporal_type_desc, t.history_retention_period,
         t.is_ledger_table, t.is_tracked_by_cdc, t.is_memory_optimized,
         hs.name, ht.name
ORDER BY s.name, t.name;

-- 3. Columns that could hold personal identifiers (name, email, phone, customer id, etc.)
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
  AND (c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%customer%' OR c.name LIKE '%subject%' OR c.name LIKE '%person%'
       OR c.name LIKE '%contact%' OR c.name LIKE '%addr%' OR c.name LIKE '%user%'
       OR c.name LIKE '%valid_%')
ORDER BY s.name, t.name, c.column_id;

-- 4. Columns of type text/binary/xml/json-like that could contain PII inside free-form content
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sql_variant')
ORDER BY s.name, t.name, c.column_id;

-- 5. Non-clustered / full-text indexes on the customer table (index copies may retain values)
SELECT s.name AS schema_name,
       t.name AS table_name,
       i.name AS index_name,
       i.type_desc,
       i.is_unique,
       i.is_disabled
FROM sys.indexes AS i
JOIN sys.tables AS t ON t.object_id = i.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND t.name = 'customer'
ORDER BY i.index_id;

-- 6. Full-text catalogs/indexes present in the database
SELECT OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
       OBJECT_NAME(fi.object_id) AS table_name,
       fc.name AS fulltext_catalog
FROM sys.fulltext_indexes AS fi
LEFT JOIN sys.fulltext_catalogs AS fc ON fc.fulltext_catalog_id = fi.fulltext_catalog_id;

-- 7. Programmable objects that reference customer data (copies, logs, procedures may hold values)
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
ORDER BY s.name, o.name;

-- 8. Triggers on the customer table (audit triggers may copy deleted rows elsewhere)
SELECT tr.name AS trigger_name,
       tr.is_disabled,
       tr.is_instead_of_trigger,
       te.type_desc AS event_type
FROM sys.triggers AS tr
LEFT JOIN sys.trigger_events AS te ON te.object_id = tr.object_id
WHERE tr.parent_id = OBJECT_ID('dbo.customer');

-- 9. Foreign keys referencing or referenced by customer (child tables may keep copies of the id)
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc
FROM sys.foreign_keys AS fk
WHERE fk.referenced_object_id = OBJECT_ID('dbo.customer')
   OR fk.parent_object_id = OBJECT_ID('dbo.customer');

-- 10. Query Store presence (cached query text may contain literal personal data)
SELECT name, is_query_store_on = CONVERT(bit, 0)
FROM sys.databases
WHERE database_id = DB_ID();
