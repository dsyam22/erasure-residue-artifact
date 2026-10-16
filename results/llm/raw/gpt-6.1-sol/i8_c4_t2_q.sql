SELECT
    DB_NAME() AS current_database,
    @@VERSION AS sql_server_version,
    ORIGINAL_LOGIN() AS original_login,
    USER_NAME() AS database_user,
    IS_SRVROLEMEMBER(N'sysadmin') AS is_sysadmin,
    IS_MEMBER(N'db_owner') AS is_db_owner;

SELECT
    name,
    state_desc,
    recovery_model_desc,
    compatibility_level,
    is_read_committed_snapshot_on,
    snapshot_isolation_state_desc,
    is_cdc_enabled,
    is_broker_enabled,
    is_encrypted,
    source_database_id
FROM sys.databases
WHERE name = N'llm_i8'
   OR source_database_id = DB_ID(N'llm_i8');

SELECT permission_name
FROM sys.fn_my_permissions(NULL, N'DATABASE')
ORDER BY permission_name;

SELECT permission_name
FROM sys.fn_my_permissions(NULL, N'SERVER')
ORDER BY permission_name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.is_ms_shipped,
    t.temporal_type_desc,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id) AS history_table,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.durability_desc,
    t.is_filetable,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    t.is_remote_data_archive_enabled,
    ct.is_track_columns_updated_on,
    ct.begin_version,
    ct.cleanup_version,
    (
        SELECT SUM(p.rows)
        FROM sys.partitions AS p
        WHERE p.object_id = t.object_id
          AND p.index_id IN (0, 1)
    ) AS approximate_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.collation_name,
    c.is_nullable,
    c.is_hidden,
    c.generated_always_type_desc,
    c.encryption_type_desc,
    c.is_filestream,
    cc.definition AS computed_definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE o.type IN (N'U', N'V', N'ET', N'IT')
ORDER BY s.name, o.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN (N'V', N'P', N'FN', N'IF', N'TF', N'TR')
ORDER BY s.name, o.name;

SELECT
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS synonym_name,
    base_object_name
FROM sys.synonyms;

SELECT
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_disabled,
    i.has_filter,
    i.filter_definition,
    p.partition_number,
    p.rows AS approximate_row_count,
    p.data_compression_desc
FROM sys.tables AS t
JOIN sys.indexes AS i ON i.object_id = t.object_id
JOIN sys.partitions AS p
    ON p.object_id = i.object_id AND p.index_id = i.index_id
ORDER BY schema_name, table_name, i.index_id, p.partition_number;

SELECT
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    fc.name AS fulltext_catalog,
    fi.is_enabled,
    fi.change_tracking_state_desc,
    fi.has_crawl_completed,
    c.name AS indexed_column
FROM sys.fulltext_indexes AS fi
JOIN sys.tables AS t ON t.object_id = fi.object_id
JOIN sys.fulltext_catalogs AS fc ON fc.fulltext_catalog_id = fi.fulltext_catalog_id
JOIN sys.fulltext_index_columns AS fic ON fic.object_id = fi.object_id
JOIN sys.columns AS c
    ON c.object_id = fic.object_id AND c.column_id = fic.column_id;

SELECT
    OBJECT_SCHEMA_NAME(object_id) AS internal_schema,
    name AS internal_table_name,
    internal_type_desc,
    OBJECT_SCHEMA_NAME(parent_id) AS parent_schema,
    OBJECT_NAME(parent_id) AS parent_object
FROM sys.internal_tables
ORDER BY internal_type_desc, name;

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
    SCHEMA_NAME(et.schema_id) AS schema_name,
    et.name AS external_table_name,
    eds.name AS data_source_name,
    eds.type_desc AS data_source_type,
    eds.location AS data_source_location,
    et.location AS table_location
FROM sys.external_tables AS et
JOIN sys.external_data_sources AS eds
    ON eds.data_source_id = et.data_source_id;

SELECT
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS queue_name,
    is_receive_enabled,
    is_enqueue_enabled,
    is_retention_enabled
FROM sys.service_queues
WHERE is_ms_shipped = 0;
