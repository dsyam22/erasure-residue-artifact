SELECT
    DB_NAME() AS database_name,
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
    t.is_external,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_computed,
    c.is_hidden,
    c.encryption_type_desc,
    cc.definition AS computed_definition
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    v.name AS view_name,
    v.object_id,
    i.name AS index_name,
    i.type_desc AS index_type_desc,
    m.definition
FROM sys.views AS v
JOIN sys.schemas AS s ON s.schema_id = v.schema_id
LEFT JOIN sys.indexes AS i ON i.object_id = v.object_id AND i.index_id > 0
LEFT JOIN sys.sql_modules AS m ON m.object_id = v.object_id
ORDER BY s.name, v.name, i.index_id;

SELECT
    s.name AS schema_name,
    tr.name AS trigger_name,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema_name,
    OBJECT_NAME(tr.parent_id) AS parent_object_name,
    tr.is_disabled,
    m.definition
FROM sys.triggers AS tr
LEFT JOIN sys.objects AS o ON o.object_id = tr.object_id
LEFT JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = tr.object_id
ORDER BY s.name, tr.name;

SELECT
    OBJECT_SCHEMA_NAME(ct.object_id) AS schema_name,
    OBJECT_NAME(ct.object_id) AS table_name,
    ct.is_track_columns_updated_on
FROM sys.change_tracking_tables AS ct;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON s.schema_id = sn.schema_id;

SELECT
    OBJECT_SCHEMA_NAME(sp.object_id) AS policy_schema_name,
    sp.name AS policy_name,
    sp.is_enabled,
    OBJECT_SCHEMA_NAME(pr.target_object_id) AS target_schema_name,
    OBJECT_NAME(pr.target_object_id) AS target_object_name,
    pr.predicate_type_desc,
    pr.operation_desc,
    pr.predicate_definition
FROM sys.security_policies AS sp
JOIN sys.security_predicates AS pr ON pr.object_id = sp.object_id;

SELECT
    USER_NAME() AS database_user,
    IS_MEMBER(N'db_owner') AS is_db_owner,
    HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'SELECT') AS can_select_database;
