SET NOCOUNT ON;

-- 1. All user tables, with temporal (history) and CDC/Change Tracking status
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.history_table_id,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    CASE WHEN ctt.object_id IS NOT NULL THEN 1 ELSE 0 END AS change_tracking_enabled
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ctt ON ctt.object_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

-- 2. Text-capable columns across all user tables (candidates for holding personal data)
SELECT
    s.name AS schema_name,
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
  AND ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
ORDER BY s.name, t.name, c.column_id;

-- 3. Triggers that could copy data elsewhere (audit/log tables)
SELECT
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
    OBJECT_NAME(tr.parent_id) AS parent_table,
    tr.name AS trigger_name,
    tr.is_disabled,
    OBJECTPROPERTY(tr.object_id, 'ExecIsUpdateTrigger') AS is_update_trigger,
    OBJECTPROPERTY(tr.object_id, 'ExecIsDeleteTrigger') AS is_delete_trigger,
    OBJECTPROPERTY(tr.object_id, 'ExecIsInsertTrigger') AS is_insert_trigger,
    OBJECT_DEFINITION(tr.object_id) AS trigger_definition
FROM sys.triggers AS tr
WHERE tr.is_ms_shipped = 0;

-- 4. Other objects that may hold copies (views, procedures, functions, synonyms)
SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('V','P','FN','IF','TF','SN','U')
ORDER BY o.type_desc, s.name, o.name;

-- 5. Current state of the erased subject in the live table (expected: no rows)
SELECT customer_id, full_name, email, phone, valid_from, valid_to
FROM dbo.customer
WHERE customer_id = 42
   OR full_name LIKE N'%Subject_0000042%'
   OR email LIKE N'%subject42@example.invalid%'
   OR phone LIKE N'%555-0000042%';

-- 6. Database-level features that can retain deleted data
SELECT
    name AS database_name,
    is_cdc_enabled,
    is_change_tracking_enabled,
    is_temporal_history_retention_enabled
FROM sys.databases
WHERE name = DB_NAME();
