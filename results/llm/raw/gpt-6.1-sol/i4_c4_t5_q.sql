SELECT
    DB_NAME() AS database_name,
    d.compatibility_level,
    d.is_cdc_enabled,
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
    t.is_filetable,
    t.ledger_type_desc,
    t.ledger_view_id,
    t.is_dropped_ledger_table
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
    ty.name AS declared_type,
    TYPE_NAME(c.system_type_id) AS system_type,
    c.max_length,
    c.precision,
    c.scale,
    c.collation_name,
    c.is_nullable,
    c.is_computed,
    c.is_hidden,
    c.generated_always_type_desc,
    c.encryption_type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
WHERE o.type IN ('U', 'V')
ORDER BY s.name, o.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    p.name AS period_name,
    cs.name AS start_column_name,
    ce.name AS end_column_name
FROM sys.periods AS p
JOIN sys.tables AS t ON t.object_id = p.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS cs
  ON cs.object_id = p.object_id AND cs.column_id = p.start_column_id
JOIN sys.columns AS ce
  ON ce.object_id = p.object_id AND ce.column_id = p.end_column_id;

SELECT
    s.name AS parent_schema_name,
    o.name AS parent_object_name,
    tr.name AS trigger_name,
    tr.is_disabled,
    tr.is_instead_of_trigger,
    sm.definition
FROM sys.triggers AS tr
LEFT JOIN sys.objects AS o ON o.object_id = tr.parent_id
LEFT JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS sm ON sm.object_id = tr.object_id;

SELECT
    s.name AS schema_name,
    o.name AS module_name,
    o.type_desc,
    sm.definition
FROM sys.sql_modules AS sm
JOIN sys.objects AS o ON o.object_id = sm.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type <> 'TR'
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
    ct.is_track_columns_updated_on
FROM sys.change_tracking_tables AS ct;

SELECT
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS can_select_database,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DATABASE STATE') AS can_view_database_state,
    IS_MEMBER('db_owner') AS is_db_owner,
    IS_SRVROLEMEMBER('sysadmin') AS is_sysadmin;
