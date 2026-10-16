SELECT
    DB_NAME() AS database_name,
    d.is_cdc_enabled,
    d.is_broker_enabled,
    d.snapshot_isolation_state_desc
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
    t.is_filetable
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
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
    ct.begin_version,
    ct.cleanup_version,
    ct.min_valid_version,
    ct.is_track_columns_updated_on
FROM sys.change_tracking_tables AS ct
JOIN sys.tables AS t ON t.object_id = ct.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    it.name AS internal_table_name,
    it.internal_type_desc
FROM sys.internal_tables AS it
LEFT JOIN sys.objects AS o ON o.object_id = it.parent_id
LEFT JOIN sys.schemas AS s ON s.schema_id = o.schema_id
ORDER BY s.name, o.name, it.name;

SELECT
    USER_NAME() AS database_user,
    IS_MEMBER(N'db_owner') AS is_db_owner,
    HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'SELECT') AS can_select_database,
    HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DATABASE STATE') AS can_view_database_state;
