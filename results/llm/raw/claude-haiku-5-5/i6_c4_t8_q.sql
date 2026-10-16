-- Read-only inventory: where could a phone number still live in llm_i6?

-- 1. All columns whose names suggest phone/contact data
SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name,
       ty.name AS data_type, c.max_length, c.is_computed
FROM sys.columns c
JOIN sys.tables t  ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty  ON c.user_type_id = ty.user_type_id
WHERE c.name LIKE '%phone%' OR c.name LIKE '%tel%' OR c.name LIKE '%mobile%'
   OR c.name LIKE '%cell%' OR c.name LIKE '%fax%' OR c.name LIKE '%contact%'
ORDER BY s.name, t.name, c.name;

-- 2. Current column list of dbo.customer (confirm the phone column is gone)
SELECT c.column_id, c.name, ty.name AS data_type, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.customer')
ORDER BY c.column_id;

-- 3. Every table and its row count (candidates for copies such as history, audit, staging, archive)
SELECT s.name AS schema_name, t.name AS table_name, t.temporal_type_desc,
       t.is_tracked_by_cdc, SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc
ORDER BY s.name, t.name;

-- 4. Modules (views, procedures, functions, triggers) whose definitions mention phone
SELECT o.type_desc, s.name AS schema_name, o.name AS object_name
FROM sys.sql_modules m
JOIN sys.objects o  ON m.object_id = o.object_id
JOIN sys.schemas s  ON o.schema_id = s.schema_id
WHERE m.definition LIKE '%phone%';

-- 5. Foreign keys and default constraints referencing customer (possible dependent copies)
SELECT fk.name AS constraint_name, OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR fk.parent_object_id = OBJECT_ID(N'dbo.customer');

-- 6. Full-text indexes and columns (indexed text may retain removed values)
SELECT OBJECT_SCHEMA_NAME(fc.object_id) AS schema_name, OBJECT_NAME(fc.object_id) AS table_name, col.name AS column_name
FROM sys.fulltext_index_columns fc
JOIN sys.columns col ON fc.object_id = col.object_id AND fc.column_id = col.column_id;
