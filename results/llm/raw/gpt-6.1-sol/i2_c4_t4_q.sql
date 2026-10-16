SELECT
    DB_NAME() AS database_name,
    d.collation_name,
    d.is_cdc_enabled,
    d.snapshot_isolation_state_desc,
    d.is_read_committed_snapshot_on
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.durability_desc,
    t.ledger_type_desc,
    t.is_dropped_ledger_table
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_computed,
    c.generated_always_type_desc,
    c.is_hidden,
    c.encryption_type_desc,
    cc.definition AS computed_definition
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    tr.name AS trigger_name,
    tr.is_disabled,
    tr.is_instead_of_trigger,
    m.definition
FROM sys.triggers AS tr
JOIN sys.tables AS t ON t.object_id = tr.parent_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = tr.object_id
ORDER BY s.name, t.name, tr.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    p.name AS period_name,
    sc.name AS period_start_column,
    ec.name AS period_end_column
FROM sys.periods AS p
JOIN sys.tables AS t ON t.object_id = p.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS sc
    ON sc.object_id = p.object_id AND sc.column_id = p.start_column_id
JOIN sys.columns AS ec
    ON ec.object_id = p.object_id AND ec.column_id = p.end_column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    ct.is_track_columns_updated_on,
    ct.begin_version,
    ct.min_valid_version,
    ct.cleanup_version
FROM sys.change_tracking_tables AS ct
JOIN sys.tables AS t ON t.object_id = ct.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

SELECT
    name AS synonym_name,
    SCHEMA_NAME(schema_id) AS schema_name,
    base_object_name
FROM sys.synonyms;

SELECT
    USER_NAME() AS database_user,
    IS_MEMBER('db_owner') AS is_db_owner,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS can_select_database;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    sp.name AS security_policy_name,
    sp.is_enabled,
    pr.predicate_type_desc,
    pr.operation_desc,
    pr.predicate_definition
FROM sys.security_predicates AS pr
JOIN sys.security_policies AS sp ON sp.object_id = pr.object_id
JOIN sys.objects AS o ON o.object_id = pr.target_object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id;
