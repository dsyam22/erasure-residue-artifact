SELECT
    DB_NAME() AS database_name,
    d.state_desc,
    d.recovery_model_desc,
    d.is_cdc_enabled,
    d.is_broker_enabled,
    d.snapshot_isolation_state_desc,
    d.is_read_committed_snapshot_on,
    d.source_database_id,
    d.is_encrypted,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DATABASE STATE') AS can_view_database_state,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DATABASE PERFORMANCE STATE') AS can_view_database_performance_state,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS has_database_select,
    IS_SRVROLEMEMBER('sysadmin') AS is_sysadmin
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema,
    ty.name AS declared_type,
    TYPE_NAME(c.system_type_id) AS base_type,
    c.max_length,
    c.precision,
    c.scale,
    c.collation_name,
    c.is_nullable,
    c.is_computed,
    c.is_hidden,
    c.generated_always_type_desc,
    c.encryption_type_desc,
    cc.definition AS computed_definition,
    HAS_PERMS_BY_NAME(QUOTENAME(s.name) + '.' + QUOTENAME(o.name), 'OBJECT', 'SELECT') AS can_select
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE o.type IN ('U', 'V')
ORDER BY s.name, o.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    hs.name AS history_schema,
    ht.name AS history_table,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.durability_desc,
    t.is_filetable,
    t.is_external,
    t.is_remote_data_archive_enabled,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    ct.is_track_columns_updated_on,
    ct.begin_version AS change_tracking_begin_version,
    ct.cleanup_version AS change_tracking_cleanup_version
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.index_id,
    i.name AS index_name,
    i.type_desc,
    i.is_disabled,
    p.partition_number,
    p.rows AS approximate_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.indexes AS i ON i.object_id = t.object_id
JOIN sys.partitions AS p
    ON p.object_id = i.object_id AND p.index_id = i.index_id
ORDER BY s.name, t.name, i.index_id, p.partition_number;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition,
    m.execute_as_principal_id
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.type IN ('TR', 'V', 'P', 'FN', 'IF', 'TF')
ORDER BY s.name, o.name;

SELECT
    tr.name AS trigger_name,
    tr.parent_class_desc,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
    OBJECT_NAME(tr.parent_id) AS parent_object,
    tr.is_disabled,
    tr.is_instead_of_trigger,
    m.definition
FROM sys.triggers AS tr
LEFT JOIN sys.sql_modules AS m ON m.object_id = tr.object_id;

SELECT
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS synonym_name,
    base_object_name
FROM sys.synonyms;

SELECT
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    it.name AS internal_table_name,
    it.internal_type_desc
FROM sys.internal_tables AS it
LEFT JOIN sys.tables AS t ON t.object_id = it.parent_id
ORDER BY schema_name, table_name, internal_table_name;

SELECT
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    fi.is_enabled,
    fi.change_tracking_state_desc,
    c.name AS fulltext_column,
    TYPE_NAME(c.system_type_id) AS base_type
FROM sys.fulltext_indexes AS fi
JOIN sys.tables AS t ON t.object_id = fi.object_id
JOIN sys.fulltext_index_columns AS fic ON fic.object_id = fi.object_id
JOIN sys.columns AS c
    ON c.object_id = fic.object_id AND c.column_id = fic.column_id;

SELECT
    sp.name AS security_policy,
    sp.is_enabled,
    OBJECT_SCHEMA_NAME(pr.target_object_id) AS target_schema,
    OBJECT_NAME(pr.target_object_id) AS target_object,
    pr.predicate_type_desc,
    pr.operation_desc,
    pr.predicate_definition
FROM sys.security_policies AS sp
JOIN sys.security_predicates AS pr ON pr.object_id = sp.object_id;

SELECT
    name AS logical_file_name,
    type_desc,
    physical_name,
    size AS size_in_8kb_pages,
    state_desc
FROM sys.database_files;

SELECT
    name AS database_or_snapshot_name,
    state_desc,
    source_database_id
FROM sys.databases
WHERE database_id = DB_ID()
   OR source_database_id = DB_ID();

SELECT
    class_desc,
    major_id,
    minor_id,
    name AS property_name,
    value AS property_value
FROM sys.extended_properties
ORDER BY class, major_id, minor_id, name;
