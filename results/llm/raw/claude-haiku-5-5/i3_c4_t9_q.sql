SET NOCOUNT ON;

-- 1. All user tables: temporal, CDC, change tracking, history links, row counts
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.is_tracked_by_cdc,
       CASE WHEN ct.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled,
       h.name AS history_table_name,
       p.row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
LEFT JOIN sys.tables AS h ON h.object_id = t.history_table_id
LEFT JOIN (
    SELECT object_id, SUM(rows) AS row_count
    FROM sys.partitions
    WHERE index_id IN (0, 1)
    GROUP BY object_id
) AS p ON p.object_id = t.object_id
ORDER BY s.name, t.name;

-- 2. Tables and views with columns that may hold personal data
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length
FROM sys.columns AS c
JOIN sys.objects AS o ON o.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V')
  AND (   c.name LIKE '%name%'
       OR c.name LIKE '%mail%'
       OR c.name LIKE '%phone%'
       OR c.name LIKE '%addr%'
       OR c.name LIKE '%cust%'
       OR c.name LIKE '%member%'
       OR c.name LIKE '%subject%'
       OR c.name LIKE '%user%'
       OR c.name LIKE '%contact%'
       OR c.name LIKE '%birth%'
       OR c.name LIKE '%ssn%')
ORDER BY s.name, o.name, c.column_id;

-- 3. Programmable objects (views, procedures, triggers, functions) referencing the subject or related tables
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE m.definition LIKE N'%customer%'
   OR m.definition LIKE N'%member%'
   OR m.definition LIKE N'%Subject[_]0000042%'
   OR m.definition LIKE N'%subject42@%'
   OR m.definition LIKE N'%example.invalid%'
   OR m.definition LIKE N'%555-0000042%';

-- 4. Direct residual check in dbo.customer
SELECT N'dbo.customer' AS source_table,
       COUNT(*) AS matching_rows
FROM dbo.customer
WHERE customer_id = 42
   OR full_name LIKE N'%Subject[_]0000042%'
   OR email LIKE N'%subject42@%'
   OR phone LIKE N'%555-0000042%';

-- 5. Direct residual check in dbo.member
SELECT N'dbo.member' AS source_table,
       COUNT(*) AS matching_rows
FROM dbo.member
WHERE member_id = 42
   OR full_name LIKE N'%Subject[_]0000042%'
   OR email LIKE N'%subject42@%'
   OR phone LIKE N'%555-0000042%';

-- 6. Query Store captured query text containing the subject's identifiers or table references
SELECT qt.query_text_id,
       qt.query_sql_text
FROM sys.query_store_query_text AS qt
WHERE qt.query_sql_text LIKE N'%Subject[_]0000042%'
   OR qt.query_sql_text LIKE N'%subject42@%'
   OR qt.query_sql_text LIKE N'%555-0000042%';
