SELECT
    DB_NAME() AS database_name,
    d.database_id,
    d.state_desc,
    d.recovery_model_desc,
    d.snapshot_isolation_state_desc,
    d.is_read_committed_snapshot_on,
    d.is_cdc_enabled,
    d.is_encrypted,
    d.is_broker_enabled,
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
    t.is_ms_shipped,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema_name,
    OBJECT_NAME(t.history_table_id) AS history_table_name,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.durability_desc,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    t.filestream_data_space_id,
    t.lob_data_space_id,
    ct.is_track_columns_updated_on,
    p.approximate_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
OUTER APPLY
(
    SELECT SUM(part.rows) AS approximate_rows
    FROM sys.partitions AS part
    WHERE part.object_id = t.object_id
      AND part.index_id IN (0, 1)
) AS p
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
    c.encryption_type_desc,
    c.is_filestream
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE o.type IN ('U', 'V', 'ET', 'IT')
ORDER BY s.name, o.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.is_schema_bound,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
ORDER BY s.name, o.name;

SELECT
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS synonym_name,
    base_object_name
FROM sys.synonyms
ORDER BY schema_name, synonym_name;

SELECT
    OBJECT_SCHEMA_NAME(object_id) AS schema_name,
    OBJECT_NAME(object_id) AS table_name,
    index_id,
    name AS index_name,
    type_desc,
    is_disabled,
    has_filter,
    filter_definition,
    data_space_id
FROM sys.indexes
WHERE object_id IN (SELECT object_id FROM sys.tables)
ORDER BY schema_name, table_name, index_id;

SELECT
    OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
    OBJECT_NAME(fi.object_id) AS table_name,
    fc.name AS fulltext_catalog_name,
    fi.is_enabled,
    fi.change_tracking_state_desc,
    fi.has_crawl_completed,
    COL_NAME(fic.object_id, fic.column_id) AS indexed_column_name
FROM sys.fulltext_indexes AS fi
JOIN sys.fulltext_catalogs AS fc
    ON fc.fulltext_catalog_id = fi.fulltext_catalog_id
JOIN sys.fulltext_index_columns AS fic ON fic.object_id = fi.object_id
ORDER BY schema_name, table_name, indexed_column_name;

SELECT
    file_id,
    name AS logical_file_name,
    type_desc,
    state_desc,
    physical_name,
    size AS size_in_8kb_pages,
    is_sparse
FROM sys.database_files
ORDER BY file_id;

SELECT
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS external_table_name,
    location,
    data_source_id,
    file_format_id
FROM sys.external_tables;

SELECT
    name AS external_data_source_name,
    type_desc,
    location
FROM sys.external_data_sources;

SELECT
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS security_policy_name,
    is_enabled
FROM sys.security_policies;

SELECT
    OBJECT_SCHEMA_NAME(target_object_id) AS target_schema,
    OBJECT_NAME(target_object_id) AS target_object,
    predicate_type_desc,
    operation_desc,
    predicate_definition
FROM sys.security_predicates;

SELECT
    class_desc,
    major_id,
    minor_id,
    name AS property_name,
    CONVERT(nvarchar(max), value) AS property_value
FROM sys.extended_properties;
