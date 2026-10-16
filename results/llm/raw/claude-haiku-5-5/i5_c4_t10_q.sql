SET NOCOUNT ON;

-- 1. Database-level change capture / versioning flags
SELECT d.name AS database_name,
       d.is_cdc_enabled,
       d.is_change_tracking_enabled,
       d.compatibility_level
FROM sys.databases d
WHERE d.database_id = DB_ID();

-- 2. All user tables, including temporal (system-versioned) and history relationships
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.object_id,
       t.temporal_type_desc,
       t.history_table_id,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       t.is_ms_shipped,
       t.create_date,
       t.modify_date
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name;

-- 3. Columns that could hold personal data (name, email, phone, customer id), in any table
SELECT s.name AS schema_name,
       t.name AS table_name,
       c.column_id,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length,
       c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
ORDER BY s.name, t.name, c.column_id;

-- 4. Tables whose names suggest copies, history, logs, or staging
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.name LIKE '%hist%'
   OR t.name LIKE '%audit%'
   OR t.name LIKE '%log%'
   OR t.name LIKE '%archive%'
   OR t.name LIKE '%backup%'
   OR t.name LIKE '%stag%'
   OR t.name LIKE '%tmp%'
   OR t.name LIKE '%temp%'
   OR t.name LIKE '%copy%'
   OR t.name LIKE '%bak%'
   OR t.name LIKE '%customer%'
ORDER BY s.name, t.name;

-- 5. Change tracking tables
SELECT OBJECT_SCHEMA_NAME(ctt.object_id) AS schema_name,
       OBJECT_NAME(ctt.object_id) AS table_name,
       ctt.is_track_columns_updated_on
FROM sys.change_tracking_tables ctt;

-- 6. Triggers on user tables (may copy deleted rows elsewhere)
SELECT OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
       OBJECT_NAME(tr.parent_id) AS table_name,
       tr.name AS trigger_name,
       tr.is_disabled,
       tr.is_instead_of_trigger
FROM sys.triggers tr
WHERE tr.is_ms_shipped = 0;

-- 7. Modules (procs, functions, views) that reference customer data columns
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
ORDER BY s.name, o.name;

-- 8. Current state of dbo.customer for the subject (customer_id 42)
SELECT c.customer_id, c.full_name, c.email, c.phone, c.valid_from, c.valid_to
FROM dbo.customer c
WHERE c.customer_id = 42;

-- 9. Searchable residual check on the subject's identifiers across the current customer table
SELECT COUNT(*) AS rows_with_subject_identifiers
FROM dbo.customer c
WHERE c.full_name = N'Subject_0000042'
   OR c.email = N'subject42@example.invalid'
   OR c.phone = N'+1-555-0000042';
