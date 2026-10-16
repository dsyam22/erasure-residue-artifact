SELECT
    d.name,
    d.temporal_history_retention_enabled,
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
    t.history_retention_period,
    t.history_retention_period_unit_desc,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.is_external,
    t.ledger_type_desc,
    t.ledger_view_id,
    t.is_dropped_ledger_table,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_hidden,
    c.generated_always_type_desc,
    c.encryption_type_desc,
    p.start_column_id AS period_start_column_id,
    p.end_column_id AS period_end_column_id
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.periods AS p ON p.object_id = t.object_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    v.name AS view_name,
    v.object_id,
    m.definition,
    CASE WHEN EXISTS
        (SELECT 1 FROM sys.indexes AS i
         WHERE i.object_id = v.object_id AND i.index_id = 1)
        THEN 1 ELSE 0 END AS is_indexed_view
FROM sys.views AS v
JOIN sys.schemas AS s ON s.schema_id = v.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = v.object_id
ORDER BY s.name, v.name;

SELECT
    s.name AS schema_name,
    tr.name AS trigger_name,
    tr.parent_class_desc,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema_name,
    OBJECT_NAME(tr.parent_id) AS parent_object_name,
    tr.is_disabled,
    tr.is_instead_of_trigger,
    m.definition
FROM sys.triggers AS tr
LEFT JOIN sys.objects AS o ON o.object_id = tr.object_id
LEFT JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = tr.object_id
ORDER BY tr.name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type NOT IN ('V', 'TR')
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON s.schema_id = sn.schema_id
ORDER BY s.name, sn.name;

SELECT
    OBJECT_SCHEMA_NAME(ct.object_id) AS schema_name,
    OBJECT_NAME(ct.object_id) AS table_name,
    ct.is_track_columns_updated_on,
    ct.begin_version,
    ct.cleanup_version
FROM sys.change_tracking_tables AS ct;

SELECT
    OBJECT_SCHEMA_NAME(sp.target_object_id) AS target_schema_name,
    OBJECT_NAME(sp.target_object_id) AS target_object_name,
    sp.predicate_definition,
    sp.predicate_type_desc,
    sp.operation_desc,
    pol.name AS policy_name,
    pol.is_enabled
FROM sys.security_predicates AS sp
JOIN sys.security_policies AS pol ON pol.object_id = sp.object_id;

SELECT
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS can_select_database,
    HAS_PERMS_BY_NAME(NULL, 'SERVER', 'VIEW SERVER STATE') AS can_view_server_state,
    HAS_PERMS_BY_NAME(NULL, 'SERVER', 'VIEW SERVER PERFORMANCE STATE') AS can_view_server_performance_state;

SELECT
    file_id,
    name,
    type_desc,
    physical_name,
    state_desc
FROM sys.database_files;
