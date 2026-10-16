SELECT
    DB_NAME() AS database_name,
    d.compatibility_level,
    d.recovery_model_desc,
    d.is_cdc_enabled,
    d.is_broker_enabled,
    d.snapshot_isolation_state_desc,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DATABASE STATE') AS can_view_database_state,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DATABASE PERFORMANCE STATE') AS can_view_database_performance_state,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    IS_MEMBER('db_owner') AS is_db_owner,
    IS_SRVROLEMEMBER('sysadmin') AS is_sysadmin
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
    t.is_dropped_ledger_table,
    t.is_filetable,
    t.is_external,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema_name,
    ty.name AS type_name,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_computed,
    c.is_hidden,
    c.generated_always_type_desc,
    c.encryption_type_desc,
    c.collation_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('V', 'TR', 'P', 'FN', 'IF', 'TF')
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_disabled,
    i.has_filter,
    i.filter_definition,
    p.partition_number,
    p.rows AS estimated_rows,
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
    ct.begin_version,
    ct.cleanup_version,
    ct.min_valid_version,
    ct.is_track_columns_updated_on
FROM sys.change_tracking_tables AS ct
JOIN sys.tables AS t ON t.object_id = ct.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    fc.name AS fulltext_catalog_name,
    fi.is_enabled,
    fi.change_tracking_state_desc,
    fi.has_crawl_completed
FROM sys.fulltext_indexes AS fi
JOIN sys.tables AS t ON t.object_id = fi.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.fulltext_catalogs AS fc
    ON fc.fulltext_catalog_id = fi.fulltext_catalog_id;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON s.schema_id = sn.schema_id;

SELECT
    name AS file_name,
    type_desc,
    physical_name,
    size AS size_in_8kb_pages,
    state_desc
FROM sys.database_files;

SELECT
    name AS database_name,
    source_database_id,
    state_desc
FROM sys.databases
WHERE source_database_id = DB_ID();

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    sp.name AS security_policy_name,
    sp.is_enabled,
    pr.predicate_type_desc,
    pr.operation_desc,
    pr.predicate_definition
FROM sys.security_predicates AS pr
JOIN sys.security_policies AS sp ON sp.object_id = pr.object_id
JOIN sys.tables AS t ON t.object_id = pr.target_object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    c.masking_function
FROM sys.masked_columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE c.is_masked = 1;
