SELECT
    DB_NAME() AS database_name,
    d.database_id,
    d.compatibility_level,
    d.recovery_model_desc,
    d.snapshot_isolation_state_desc,
    d.is_read_committed_snapshot_on,
    d.is_cdc_enabled,
    d.is_encrypted,
    d.is_published,
    d.is_subscribed,
    d.is_distributor,
    d.source_database_id,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DATABASE STATE') AS can_view_database_state,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DATABASE PERFORMANCE STATE') AS can_view_database_performance_state,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS has_database_select
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
    t.is_filetable,
    t.is_external,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    t.is_replicated,
    t.is_merge_published,
    t.is_ms_shipped,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema_name,
    ty.name AS type_name,
    c.max_length,
    c.precision,
    c.scale,
    c.collation_name,
    c.is_nullable,
    c.is_computed,
    cc.definition AS computed_definition,
    c.generated_always_type_desc,
    c.encryption_type_desc,
    c.is_hidden,
    c.is_masked,
    mc.masking_function,
    HAS_PERMS_BY_NAME(QUOTENAME(s.name) + '.' + QUOTENAME(t.name), 'OBJECT', 'SELECT') AS can_select
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
LEFT JOIN sys.masked_columns AS mc
    ON mc.object_id = c.object_id AND mc.column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.index_id,
    i.name AS index_name,
    i.type_desc,
    i.is_disabled,
    SUM(p.rows) AS approximate_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.indexes AS i ON i.object_id = t.object_id
LEFT JOIN sys.partitions AS p
    ON p.object_id = i.object_id AND p.index_id = i.index_id
GROUP BY s.name, t.name, i.index_id, i.name, i.type_desc, i.is_disabled
ORDER BY s.name, t.name, i.index_id;

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
    s.name AS schema_name,
    sy.name AS synonym_name,
    sy.base_object_name
FROM sys.synonyms AS sy
JOIN sys.schemas AS s ON s.schema_id = sy.schema_id;

SELECT
    OBJECT_SCHEMA_NAME(ct.object_id) AS schema_name,
    OBJECT_NAME(ct.object_id) AS table_name,
    ct.is_track_columns_updated_on,
    ct.begin_version,
    ct.cleanup_version,
    ct.min_valid_version
FROM sys.change_tracking_tables AS ct;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    sp.name AS policy_name,
    sp.is_enabled,
    pr.predicate_definition,
    pr.predicate_type_desc,
    pr.operation_desc
FROM sys.security_policies AS sp
JOIN sys.security_predicates AS pr ON pr.object_id = sp.object_id
JOIN sys.objects AS o ON o.object_id = pr.target_object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id;

SELECT
    name AS logical_file_name,
    type_desc,
    physical_name,
    size AS size_in_8kb_pages,
    state_desc
FROM sys.database_files;

SELECT
    name AS database_name,
    database_id,
    source_database_id,
    state_desc
FROM sys.databases
WHERE source_database_id = DB_ID();

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    fi.is_enabled,
    fc.name AS fulltext_catalog_name,
    c.name AS indexed_column
FROM sys.fulltext_indexes AS fi
JOIN sys.tables AS t ON t.object_id = fi.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.fulltext_catalogs AS fc ON fc.fulltext_catalog_id = fi.fulltext_catalog_id
JOIN sys.fulltext_index_columns AS fic ON fic.object_id = fi.object_id
JOIN sys.columns AS c ON c.object_id = fic.object_id AND c.column_id = fic.column_id;
