SELECT
    DB_NAME() AS database_name,
    d.collation_name,
    d.is_cdc_enabled,
    d.snapshot_isolation_state_desc
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
    t.is_external,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_hidden,
    c.is_computed,
    c.encryption_type_desc,
    cc.definition AS computed_definition
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.columns AS c ON c.object_id = t.object_id
LEFT JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition,
    OBJECTPROPERTYEX(o.object_id, 'IsEncrypted') AS is_encrypted
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('V', 'P', 'FN', 'IF', 'TF', 'TR')
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON s.schema_id = sn.schema_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    ct.is_track_columns_updated_on,
    ct.begin_version,
    ct.cleanup_version,
    ct.min_valid_version
FROM sys.change_tracking_tables AS ct
JOIN sys.tables AS t ON t.object_id = ct.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

SELECT
    name,
    type_desc,
    physical_name
FROM sys.database_files;

SELECT
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS can_select_database,
    IS_MEMBER('db_owner') AS is_db_owner,
    IS_SRVROLEMEMBER('sysadmin') AS is_sysadmin;
