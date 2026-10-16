-- 1. All user tables with row counts, temporal/CDC/change-tracking status
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       ct.object_id AS change_tracking_object_id,
       SUM(p.rows) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables ct ON ct.object_id = t.object_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.temporal_type_desc, t.history_table_id, t.is_tracked_by_cdc, ct.object_id
ORDER BY s.name, t.name;

-- 2. Columns across the database that could hold personal data
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND (c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
       OR c.name LIKE '%customer%' OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%' OR c.name LIKE '%addr%'
       OR TYPE_NAME(c.user_type_id) IN ('xml','text','ntext','image','sql_variant','nvarchar','varchar','nchar','char')
       OR c.max_length = -1)
ORDER BY s.name, t.name, c.column_id;

-- 3. Any stored object (views, procs, triggers, functions, defaults) whose definition mentions the erased values
SELECT o.type_desc,
       s.name AS schema_name,
       o.name AS object_name,
       m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%Subject[_]0000042%'
   OR m.definition LIKE '%subject42@example%'
   OR m.definition LIKE '%555-0000042%'
   OR m.definition LIKE '%customer_id = 42%';

-- 4. Remaining rows in the base table that match the subject's identifiers
SELECT customer_id, full_name, email, phone, valid_from, valid_to
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- 5. Check for a history table reference in dbo.customer's temporal setup, if any
SELECT t.name AS table_name,
       h.name AS history_table_name,
       hs.name AS history_schema_name,
       t.temporal_type_desc
FROM sys.tables t
LEFT JOIN sys.tables h ON h.object_id = t.history_table_id
LEFT JOIN sys.schemas hs ON hs.schema_id = h.schema_id
WHERE t.name = 'customer';

-- 6. Full-text, query store and plan cache checks for literal values (text search only)
SELECT TOP (50) qt.query_sql_text
FROM sys.query_store_query_text qt
WHERE qt.query_sql_text LIKE '%subject42%'
   OR qt.query_sql_text LIKE '%Subject[_]0000042%'
   OR qt.query_sql_text LIKE '%555-0000042%';
