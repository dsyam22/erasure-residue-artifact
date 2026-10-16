-- Read-only inspection: where could erased personal data still live?

-- 1. Database-level tracking features
SELECT 'database' AS scope,
       d.name AS object_name,
       CAST(d.is_cdc_enabled AS int) AS flag1,
       CAST(CASE WHEN ctd.database_id IS NULL THEN 0 ELSE 1 END AS int) AS flag2,
       ctd.retention_period AS detail
FROM sys.databases AS d
LEFT JOIN sys.change_tracking_databases AS ctd ON ctd.database_id = d.database_id
WHERE d.database_id = DB_ID();

-- 2. All user tables: temporal, CDC, change tracking, row counts
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       hs.name + '.' + ht.name AS history_table,
       t.is_tracked_by_cdc,
       CASE WHEN ct.object_id IS NULL THEN 0 ELSE 1 END AS change_tracking_on,
       SUM(p.rows) AS approx_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
LEFT JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, hs.name, ht.name,
         t.is_tracked_by_cdc, ct.object_id
ORDER BY s.name, t.name;

-- 3. Columns that could hold names, emails, phones, or the subject's identifier
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
  AND (c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%customer%' OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%' OR c.name LIKE '%contact%'
       OR c.name LIKE '%user%' OR c.name LIKE '%cust%')
ORDER BY s.name, t.name, c.column_id;

-- 4. Non-clustered indexes and full-text catalogs that may hold copies of values
SELECT s.name AS schema_name,
       t.name AS table_name,
       i.name AS index_name,
       i.type_desc,
       i.is_unique,
       CAST(CASE WHEN fti.object_id IS NULL THEN 0 ELSE 1 END AS int) AS has_fulltext
FROM sys.indexes AS i
JOIN sys.tables AS t ON t.object_id = i.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.fulltext_indexes AS fti ON fti.object_id = t.object_id
WHERE t.is_ms_shipped = 0 AND i.index_id > 0
ORDER BY s.name, t.name, i.index_id;

-- 5. Programmable objects whose text mentions the customer table or PII column names
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%full_name%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
ORDER BY s.name, o.name;

-- 6. Triggers and audit-like objects
SELECT s.name AS schema_name,
       OBJECT_NAME(tr.parent_id) AS parent_table,
       tr.name AS trigger_name,
       tr.is_disabled
FROM sys.triggers AS tr
JOIN sys.objects AS o ON o.object_id = tr.parent_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE tr.is_ms_shipped = 0
ORDER BY parent_table, trigger_name;

-- 7. Server-side audit specifications and database audit specs for this database
SELECT da.name AS database_audit_spec,
       da.is_state_enabled,
       dad.audit_action_name,
       dad.audited_principal_id,
       dad.class_desc
FROM sys.database_audit_specifications AS da
JOIN sys.database_audit_specification_details AS dad
     ON dad.database_specification_id = da.database_specification_id
ORDER BY da.name;
