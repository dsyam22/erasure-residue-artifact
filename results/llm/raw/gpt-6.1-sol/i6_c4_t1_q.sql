USE [llm_i6];

SELECT
    DB_NAME() AS database_name,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS can_select_database,
    IS_MEMBER('db_owner') AS is_db_owner,
    d.recovery_model_desc,
    d.is_cdc_enabled,
    d.is_broker_enabled,
    d.source_database_id
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    o.is_ms_shipped,
    c.column_id,
    c.name AS column_name,
    TYPE_SCHEMA_NAME(ty.schema_id) AS type_schema,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_hidden,
    c.encryption_type_desc,
    cc.definition AS computed_definition,
    dc.definition AS default_definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
LEFT JOIN sys.default_constraints AS dc
    ON dc.object_id = c.default_object_id
WHERE o.type IN ('U', 'V', 'IT', 'ET')
ORDER BY s.name, o.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_memory_optimized,
    t.is_tracked_by_cdc,
    t.is_filetable,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    ct.is_track_columns_updated_on,
    (SELECT SUM(p.rows)
     FROM sys.partitions AS p
     WHERE p.object_id = t.object_id AND p.index_id IN (0, 1)) AS approximate_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
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
    class_desc,
    major_id,
    minor_id,
    name AS property_name,
    CONVERT(nvarchar(max), value) AS property_value
FROM sys.extended_properties;

SELECT
    name AS file_name,
    type_desc,
    physical_name,
    state_desc
FROM sys.database_files;
