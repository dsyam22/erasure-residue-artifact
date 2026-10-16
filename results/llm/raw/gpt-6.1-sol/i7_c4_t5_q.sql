SELECT
    d.name,
    d.state_desc,
    d.recovery_model_desc,
    d.is_cdc_enabled,
    d.snapshot_isolation_state_desc
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_hidden,
    c.encryption_type_desc
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.type IN ('V', 'TR', 'P', 'FN', 'IF', 'TF')
ORDER BY s.name, o.name;

SELECT
    OBJECT_SCHEMA_NAME(ct.object_id) AS schema_name,
    OBJECT_NAME(ct.object_id) AS table_name,
    ct.is_track_columns_updated_on
FROM sys.change_tracking_tables AS ct;

SELECT
    s.name AS schema_name,
    sy.name AS synonym_name,
    sy.base_object_name
FROM sys.synonyms AS sy
JOIN sys.schemas AS s ON s.schema_id = sy.schema_id;

SELECT
    N'dbo.customer' AS source_table,
    customer_id,
    full_name,
    email,
    phone
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

SELECT
    N'reporting.customer_replica' AS source_table,
    customer_id,
    full_name,
    email,
    phone
FROM reporting.customer_replica
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

SELECT
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS can_select_database,
    IS_SRVROLEMEMBER('sysadmin') AS is_sysadmin;
