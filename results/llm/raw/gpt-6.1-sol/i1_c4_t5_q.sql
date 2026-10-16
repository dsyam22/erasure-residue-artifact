SELECT
    DB_NAME() AS database_name,
    d.database_id,
    d.compatibility_level,
    d.recovery_model_desc,
    d.snapshot_isolation_state_desc,
    d.is_read_committed_snapshot_on,
    d.is_cdc_enabled,
    d.is_broker_enabled,
    d.is_encrypted,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DATABASE STATE') AS can_view_database_state,
    IS_SRVROLEMEMBER('sysadmin') AS is_sysadmin
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.is_ms_shipped,
    t.temporal_type_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.durability_desc,
    t.is_external,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_computed,
    cc.definition AS computed_definition,
    c.generated_always_type_desc,
    c.encryption_type_desc,
    c.is_hidden,
    c.is_masked
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

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
    o.parent_object_id,
    tr.is_disabled AS trigger_is_disabled,
    tr.is_instead_of_trigger,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = o.object_id
LEFT JOIN sys.triggers AS tr ON tr.object_id = o.object_id
WHERE o.type IN ('V', 'TR', 'P', 'FN', 'IF', 'TF')
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON s.schema_id = sn.schema_id;

SELECT
    OBJECT_SCHEMA_NAME(ct.object_id) AS schema_name,
    OBJECT_NAME(ct.object_id) AS table_name,
    ct.*
FROM sys.change_tracking_tables AS ct;

SELECT *
FROM sys.change_tracking_databases
WHERE database_id = DB_ID();

SELECT
    name,
    type_desc,
    physical_name,
    size,
    state_desc
FROM sys.database_files;

SELECT
    sp.name AS security_policy_name,
    sp.is_enabled,
    OBJECT_SCHEMA_NAME(pr.target_object_id) AS target_schema,
    OBJECT_NAME(pr.target_object_id) AS target_object,
    pr.predicate_definition,
    pr.predicate_type_desc,
    pr.operation_desc
FROM sys.security_policies AS sp
JOIN sys.security_predicates AS pr ON pr.object_id = sp.object_id;
