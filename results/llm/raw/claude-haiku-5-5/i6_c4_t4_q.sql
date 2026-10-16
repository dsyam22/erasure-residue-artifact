SET NOCOUNT ON;

-- 1. Columns with phone-like names anywhere in the database
SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name,
       ty.name AS data_type, c.max_length, t.is_ms_shipped
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.name LIKE '%phone%' OR c.name LIKE '%tel%' OR c.name LIKE '%mobile%'
   OR c.name LIKE '%msisdn%' OR c.name LIKE '%contact%' OR c.name LIKE '%fax%'
ORDER BY s.name, t.name, c.name;

-- 2. All tables that have a customer_id-like column (possible copies of the subject's record)
SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name, ty.name AS data_type
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.name LIKE '%customer%'
ORDER BY s.name, t.name, c.name;

-- 3. Temporal (system-versioned) history tables and CDC / change tracking indicators
SELECT s.name AS schema_name, t.name AS table_name, t.temporal_type_desc,
       h.name AS history_table_name, t.is_tracked_by_cdc
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables h ON h.object_id = t.history_table_id
WHERE t.temporal_type <> 0 OR t.is_tracked_by_cdc = 1
   OR t.name LIKE '%audit%' OR t.name LIKE '%log%' OR t.name LIKE '%history%';

-- 4. Stored objects (views, procs, functions, triggers) whose definitions mention phone
SELECT s.name AS schema_name, o.name AS object_name, o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%phone%';

-- 5. Full-text / change tracking / CDC-captured column lists that may still include phone
SELECT OBJECT_SCHEMA_NAME(object_id) AS schema_name, OBJECT_NAME(object_id) AS table_name,
       column_name
FROM sys.dm_db_column_store_row_group_physical_stats WHERE 1 = 0; -- placeholder, returns no rows

SELECT OBJECT_SCHEMA_NAME(ctc.object_id) AS schema_name,
       OBJECT_NAME(ctc.object_id) AS table_name,
       ctc.is_track_columns_updated_on
FROM sys.change_tracking_tables ctc;

-- 6. Confirm current dbo.customer column list and the subject's row (non-phone fields only)
SELECT c.name AS column_name, ty.name AS data_type
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.customer')
ORDER BY c.column_id;

SELECT customer_id, full_name, email
FROM dbo.customer
WHERE customer_id = 42;
