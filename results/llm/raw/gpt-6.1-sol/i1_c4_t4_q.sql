SELECT
    d.name,
    d.state_desc,
    d.recovery_model_desc,
    d.is_cdc_enabled,
    d.snapshot_isolation_state_desc,
    d.source_database_id,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DATABASE STATE') AS can_view_database_state,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'CONTROL') AS has_database_control
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
    t.is_external,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    t.is_ms_shipped,
    ct.is_track_columns_updated_on,
    ct.begin_version AS change_tracking_begin_version,
    ct.min_valid_version AS change_tracking_min_valid_version
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.collation_name,
    c.is_nullable,
    c.is_computed,
    cc.definition AS computed_definition,
    c.generated_always_type_desc,
    c.is_hidden,
    c.is_masked,
    c.encryption_type_desc,
    c.is_filestream,
    c.is_column_set
FROM sys.columns AS c
JOIN sys.objects AS o ON o.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE o.type IN ('U', 'V')
ORDER BY s.name, o.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    sy.name AS synonym_name,
    sy.base_object_name
FROM sys.synonyms AS sy
JOIN sys.schemas AS s ON s.schema_id = sy.schema_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    p.partition_number,
    p.rows,
    p.data_compression_desc
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.indexes AS i ON i.object_id = t.object_id
JOIN sys.partitions AS p
    ON p.object_id = i.object_id AND p.index_id = i.index_id
ORDER BY s.name, t.name, i.index_id, p.partition_number;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    pol.name AS security_policy_name,
    pol.is_enabled,
    pr.predicate_definition,
    pr.predicate_type_desc,
    pr.operation_desc
FROM sys.security_predicates AS pr
JOIN sys.security_policies AS pol ON pol.object_id = pr.object_id
JOIN sys.tables AS t ON t.object_id = pr.target_object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

SELECT
    name,
    type_desc,
    physical_name,
    state_desc
FROM sys.database_files;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    fc.name AS fulltext_catalog_name,
    c.name AS indexed_column,
    fi.change_tracking_state_desc,
    fi.has_crawl_completed
FROM sys.fulltext_indexes AS fi
JOIN sys.tables AS t ON t.object_id = fi.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.fulltext_catalogs AS fc ON fc.fulltext_catalog_id = fi.fulltext_catalog_id
JOIN sys.fulltext_index_columns AS fic ON fic.object_id = fi.object_id
JOIN sys.columns AS c
    ON c.object_id = fic.object_id AND c.column_id = fic.column_id;
