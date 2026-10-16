SELECT
    DB_NAME() AS database_name,
    USER_NAME() AS database_user,
    IS_SRVROLEMEMBER(N'sysadmin') AS is_sysadmin,
    IS_MEMBER(N'db_owner') AS is_db_owner,
    HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'SELECT') AS can_select_database,
    d.is_cdc_enabled,
    d.is_broker_enabled,
    d.snapshot_isolation_state_desc
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    o.is_ms_shipped,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema,
    ty.name AS declared_type,
    TYPE_NAME(c.system_type_id) AS system_type,
    c.max_length,
    c.is_nullable,
    c.is_computed,
    c.is_hidden,
    c.encryption_type_desc,
    cc.definition AS computed_definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE o.type IN (N'U', N'V', N'IT', N'ET')
ORDER BY s.name, o.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.is_filetable,
    t.is_external,
    t.ledger_type_desc,
    t.is_dropped_ledger_table
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name;

SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
    OBJECT_NAME(m.object_id) AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
WHERE o.is_ms_shipped = 0
ORDER BY schema_name, object_name;

SELECT
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS synonym_name,
    base_object_name
FROM sys.synonyms;

SELECT
    OBJECT_SCHEMA_NAME(parent_object_id) AS schema_name,
    OBJECT_NAME(parent_object_id) AS table_name,
    name AS constraint_name,
    definition
FROM sys.check_constraints
UNION ALL
SELECT
    OBJECT_SCHEMA_NAME(parent_object_id),
    OBJECT_NAME(parent_object_id),
    name,
    definition
FROM sys.default_constraints;

SELECT
    class_desc,
    major_id,
    minor_id,
    name AS property_name,
    CONVERT(nvarchar(max), value) AS property_value
FROM sys.extended_properties;

SELECT
    OBJECT_SCHEMA_NAME(object_id) AS schema_name,
    OBJECT_NAME(object_id) AS table_name,
    name AS policy_name,
    predicate_definition,
    predicate_type_desc,
    operation_desc
FROM sys.security_predicates;

SELECT
    OBJECT_SCHEMA_NAME(object_id) AS schema_name,
    OBJECT_NAME(object_id) AS table_name,
    internal_type_desc,
    OBJECT_SCHEMA_NAME(parent_id) AS parent_schema,
    OBJECT_NAME(parent_id) AS parent_object
FROM sys.internal_tables;

SELECT
    name AS external_data_source_name,
    type_desc,
    location,
    database_name
FROM sys.external_data_sources;
