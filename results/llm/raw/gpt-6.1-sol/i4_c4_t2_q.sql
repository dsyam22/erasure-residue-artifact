SELECT
    DB_NAME() AS database_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    d.compatibility_level,
    d.recovery_model_desc,
    d.is_cdc_enabled,
    d.is_encrypted,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS can_select_database
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
    t.is_dropped_ledger_table,
    ct.is_track_columns_updated_on AS change_tracking_tracks_columns,
    HAS_PERMS_BY_NAME(
        QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
        'OBJECT', 'SELECT'
    ) AS can_select
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema_name,
    ty.name AS data_type,
    TYPE_NAME(c.system_type_id) AS underlying_type,
    c.max_length,
    c.precision,
    c.scale,
    c.collation_name,
    c.is_nullable,
    c.is_computed,
    c.is_hidden,
    c.generated_always_type_desc,
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
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND (
      o.type IN ('TR', 'V')
      OR m.definition LIKE N'%customer%'
      OR m.definition LIKE N'%member%'
      OR m.definition LIKE N'%Subject_0000042%'
      OR m.definition LIKE N'%subject42@example.invalid%'
      OR m.definition LIKE N'%+1-555-0000042%'
  )
ORDER BY s.name, o.name;

SELECT
    tr.name AS trigger_name,
    tr.parent_class_desc,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema_name,
    OBJECT_NAME(tr.parent_id) AS parent_object_name,
    tr.is_disabled,
    tr.is_instead_of_trigger,
    OBJECT_DEFINITION(tr.object_id) AS definition
FROM sys.triggers AS tr
WHERE tr.is_ms_shipped = 0;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON s.schema_id = sn.schema_id;

SELECT
    OBJECT_SCHEMA_NAME(sp.target_object_id) AS target_schema_name,
    OBJECT_NAME(sp.target_object_id) AS target_object_name,
    OBJECT_SCHEMA_NAME(sp.object_id) AS policy_schema_name,
    OBJECT_NAME(sp.object_id) AS policy_name,
    pol.is_enabled,
    sp.predicate_type_desc,
    sp.predicate_definition
FROM sys.security_predicates AS sp
JOIN sys.security_policies AS pol ON pol.object_id = sp.object_id;

SELECT
    OBJECT_SCHEMA_NAME(fi.object_id) AS schema_name,
    OBJECT_NAME(fi.object_id) AS table_name,
    fc.name AS fulltext_catalog_name,
    fi.is_enabled,
    fi.change_tracking_state_desc,
    fi.has_crawl_completed
FROM sys.fulltext_indexes AS fi
JOIN sys.fulltext_catalogs AS fc
    ON fc.fulltext_catalog_id = fi.fulltext_catalog_id;

SELECT
    name AS database_scoped_configuration,
    value,
    value_for_secondary
FROM sys.database_scoped_configurations
WHERE name IN ('LEDGER_DIGEST_STORAGE', 'ACCELERATED_DATABASE_RECOVERY');

SELECT
    df.name AS logical_file_name,
    df.type_desc,
    df.physical_name
FROM sys.database_files AS df;
