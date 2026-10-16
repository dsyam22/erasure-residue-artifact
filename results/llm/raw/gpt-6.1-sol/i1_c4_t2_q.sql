SELECT
    DB_NAME() AS database_name,
    d.database_id,
    d.state_desc,
    d.recovery_model_desc,
    d.snapshot_isolation_state_desc,
    d.is_read_committed_snapshot_on,
    d.is_cdc_enabled,
    d.is_encrypted,
    d.source_database_id,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS can_select_database,
    IS_SRVROLEMEMBER('sysadmin') AS is_sysadmin
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
    t.is_filetable,
    ct.is_track_columns_updated_on,
    ct.begin_version AS change_tracking_begin_version,
    ct.cleanup_version AS change_tracking_cleanup_version,
    p.row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
OUTER APPLY
(
    SELECT SUM(ps.row_count) AS row_count
    FROM sys.dm_db_partition_stats AS ps
    WHERE ps.object_id = t.object_id
      AND ps.index_id IN (0, 1)
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
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.type IN ('TR', 'V', 'P', 'FN', 'IF', 'TF')
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON s.schema_id = sn.schema_id;

SELECT
    name,
    type_desc,
    physical_name,
    state_desc,
    size AS size_in_8kb_pages
FROM sys.database_files;

SELECT
    name AS snapshot_name,
    create_date,
    state_desc
FROM sys.databases
WHERE source_database_id = DB_ID();

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    fi.is_enabled,
    fi.change_tracking_state_desc,
    fc.name AS fulltext_catalog_name,
    c.name AS indexed_column
FROM sys.fulltext_indexes AS fi
JOIN sys.tables AS t ON t.object_id = fi.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.fulltext_catalogs AS fc ON fc.fulltext_catalog_id = fi.fulltext_catalog_id
JOIN sys.fulltext_index_columns AS fic ON fic.object_id = fi.object_id
JOIN sys.columns AS c
    ON c.object_id = fic.object_id AND c.column_id = fic.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    name,
    type_desc,
    is_state_enabled,
    on_failure_desc,
    create_date,
    modify_date
FROM sys.database_audit_specifications;

SELECT
    class_desc,
    major_id,
    minor_id,
    USER_NAME(grantee_principal_id) AS grantee,
    permission_name,
    state_desc
FROM sys.database_permissions
WHERE class = 0
   OR major_id = OBJECT_ID(N'dbo.customer')
ORDER BY class, major_id, grantee, permission_name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    sp.name AS security_policy,
    sp.is_enabled,
    pr.predicate_type_desc,
    pr.operation_desc,
    pr.predicate_definition
FROM sys.security_predicates AS pr
JOIN sys.security_policies AS sp ON sp.object_id = pr.object_id
JOIN sys.tables AS t ON t.object_id = pr.target_object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;
