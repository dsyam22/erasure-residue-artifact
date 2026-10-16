SET NOCOUNT ON;

-- 1. Columns whose names suggest phone/contact data, across all tables and views
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       c.column_id,
       c.name AS column_name,
       t.name AS data_type,
       c.max_length,
       c.is_nullable,
       c.is_computed
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%mobile%'
   OR c.name LIKE '%cell%'
   OR c.name LIKE '%contact%'
   OR c.name LIKE '%msisdn%'
ORDER BY s.name, o.name, c.column_id;

-- 2. All user tables with row counts, to see where customer-related data lives
SELECT s.name AS schema_name,
       t.name AS table_name,
       SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- 3. All columns in all user tables (to spot free-text, JSON, or notes columns that could hold a phone number)
SELECT s.name AS schema_name,
       o.name AS table_name,
       c.name AS column_name,
       t.name AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id AND o.type = 'U'
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.types t ON t.user_type_id = c.user_type_id
ORDER BY s.name, o.name, c.column_id;

-- 4. Module definitions (procedures, functions, triggers, views) that mention phone-related terms
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%phone%'
   OR m.definition LIKE '%mobile%'
   OR m.definition LIKE '%555-0000042%'
ORDER BY s.name, o.name;

-- 5. Check whether any user tables are change-tracked or temporal (history tables may keep old phone values)
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.temporal_type <> 0 OR t.is_tracked_by_cdc = 1
ORDER BY s.name, t.name;
