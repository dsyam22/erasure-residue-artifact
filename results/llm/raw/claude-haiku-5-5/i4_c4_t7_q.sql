-- Read-only inventory for locating residual copies of erased personal data.

-- 1. Temporal (system-versioned) tables and their history tables
SELECT s.name AS schema_name, t.name AS table_name, t.temporal_type_desc,
       h.name AS history_schema, ht.name AS history_table, t.ledger_type_desc
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS h ON h.schema_id = ht.schema_id
WHERE t.temporal_type > 0 OR t.ledger_type > 0
ORDER BY s.name, t.name;

-- 2. Every column that could hold identifiers or contact data
SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type, c.max_length, c.is_nullable
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%' OR c.name LIKE '%member%' OR c.name LIKE '%subject%'
   OR c.name LIKE '%contact%' OR c.name LIKE '%address%' OR c.name LIKE '%user%'
   OR c.name LIKE '%person%' OR c.name LIKE '%ident%'
ORDER BY s.name, t.name, c.column_id;

-- 3. Tables with free-text or large-text columns (common hiding places for copied PII)
SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE TYPE_NAME(c.user_type_id) IN ('text','ntext','xml','json','varchar','nvarchar','char','nchar')
  AND (c.max_length = -1 OR c.max_length >= 200)
ORDER BY s.name, t.name, c.name;

-- 4. Change capture, change tracking, full-text indexes
SELECT OBJECT_SCHEMA_NAME(object_id) AS schema_name, OBJECT_NAME(object_id) AS table_name,
       'change_tracking' AS feature
FROM sys.change_tracking_tables
UNION ALL
SELECT s.name, t.name, 'cdc_enabled'
FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_tracked_by_cdc = 1
UNION ALL
SELECT s.name, t.name, 'fulltext_index'
FROM sys.fulltext_indexes AS fi
JOIN sys.tables AS t ON t.object_id = fi.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

-- 5. Triggers, views and procedures that reference the two subject tables
SELECT OBJECT_SCHEMA_NAME(d.referencing_id) AS referencing_schema,
       OBJECT_NAME(d.referencing_id) AS referencing_object,
       o.type_desc, d.referenced_schema_name, d.referenced_entity_name
FROM sys.sql_expression_dependencies AS d
JOIN sys.objects AS o ON o.object_id = d.referencing_id
WHERE d.referenced_entity_name IN ('customer','member')
UNION ALL
SELECT OBJECT_SCHEMA_NAME(tr.parent_id), OBJECT_NAME(tr.parent_id), tr.type_desc,
       NULL, OBJECT_NAME(tr.object_id)
FROM sys.triggers AS tr
WHERE tr.parent_class = 1;

-- 6. Foreign keys pointing at or from the subject tables (possible copies in child tables)
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys AS fk
WHERE OBJECT_NAME(fk.referenced_object_id) IN ('customer','member')
   OR OBJECT_NAME(fk.parent_object_id) IN ('customer','member');

-- 7. Plan cache text that may still contain the literal values (read-only DMV)
SELECT TOP (50) st.text, qs.last_execution_time
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE st.text LIKE N'%Subject_0000042%'
   OR st.text LIKE N'%subject42@%'
   OR st.text LIKE N'%555-0000042%'
ORDER BY qs.last_execution_time DESC;

-- 8. Row counts for the subject tables' current state
SELECT 'customer' AS table_name, COUNT(*) AS rows_total,
       SUM(CASE WHEN customer_id = 42 THEN 1 ELSE 0 END) AS rows_id42
FROM dbo.customer
UNION ALL
SELECT 'member', COUNT(*), SUM(CASE WHEN member_id = 42 THEN 1 ELSE 0 END)
FROM dbo.member;
