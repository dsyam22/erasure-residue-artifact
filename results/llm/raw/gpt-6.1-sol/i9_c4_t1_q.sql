SELECT
    DB_NAME() AS database_name,
    d.is_cdc_enabled,
    d.snapshot_isolation_state_desc,
    d.is_read_committed_snapshot_on,
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
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    t.filestream_data_space_id,
    ct.is_track_columns_updated_on,
    p.start_column_id AS period_start_column_id,
    p.end_column_id AS period_end_column_id,
    HAS_PERMS_BY_NAME(
        QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
        'OBJECT', 'SELECT'
    ) AS can_select
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.periods AS p ON p.object_id = t.object_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema_name,
    ty.name AS declared_type,
    TYPE_NAME(c.system_type_id) AS base_type,
    c.max_length,
    c.precision,
    c.scale,
    c.collation_name,
    c.is_nullable,
    c.is_computed,
    cc.definition AS computed_definition,
    c.is_hidden,
    c.generated_always_type_desc,
    c.encryption_type_desc,
    c.is_masked
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE o.type IN ('U', 'V', 'ET')
ORDER BY s.name, o.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    sy.name AS synonym_name,
    sy.base_object_name
FROM sys.synonyms AS sy
JOIN sys.schemas AS s ON s.schema_id = sy.schema_id
ORDER BY s.name, sy.name;

SELECT
    name,
    type_desc,
    physical_name,
    state_desc
FROM sys.database_files
ORDER BY file_id;
