USE [llm_i1];
SELECT
    d.name,
    d.state_desc,
    d.recovery_model_desc,
    d.snapshot_isolation_state_desc,
    d.is_read_committed_snapshot_on,
    d.is_cdc_enabled,
    d.is_encrypted,
    d.source_database_id,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS can_select_database
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    hs.name AS history_schema,
    ht.name AS history_table,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.durability_desc,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    t.is_external,
    ct.is_track_columns_updated_on AS change_tracking_columns,
    HAS_PERMS_BY_NAME(
        QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
        'OBJECT', 'SELECT'
    ) AS can_select_table
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
    ty.name AS declared_type,
    TYPE_NAME(c.system_type_id) AS underlying_type,
    c.max_length,
    c.precision,
    c.scale,
    c.collation_name,
    c.is_nullable,
    c.is_hidden,
    c.generated_always_type_desc,
    c.encryption_type_desc,
    cc.definition AS computed_definition
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
    i.name AS index_name,
    i.type_desc,
    i.is_disabled,
    p.partition_number,
    p.rows AS approximate_rows,
    p.data_compression_desc
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
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
ORDER BY s.name, o.name;

SELECT
    tr.name AS trigger_name,
    tr.parent_class_desc,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
    OBJECT_NAME(tr.parent_id) AS parent_object,
    tr.is_disabled,
    tr.is_instead_of_trigger,
    OBJECT_DEFINITION(tr.object_id) AS definition
FROM sys.triggers AS tr;

SELECT
    s.name AS schema_name,
    sy.name AS synonym_name,
    sy.base_object_name
FROM sys.synonyms AS sy
JOIN sys.schemas AS s ON s.schema_id = sy.schema_id;

SELECT
    OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
    OBJECT_NAME(fi.object_id) AS table_name,
    fc.name AS fulltext_catalog,
    fi.is_enabled,
    fi.change_tracking_state_desc,
    fi.has_crawl_completed
FROM sys.fulltext_indexes AS fi
JOIN sys.fulltext_catalogs AS fc
    ON fc.fulltext_catalog_id = fi.fulltext_catalog_id;

SELECT
    name AS logical_file_name,
    type_desc,
    physical_name,
    size AS size_pages,
    state_desc
FROM sys.database_files;
