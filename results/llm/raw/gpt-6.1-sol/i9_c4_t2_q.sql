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
    hs.name AS history_schema,
    ht.name AS history_table,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.ledger_type_desc,
    t.is_dropped_ledger_table
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema,
    ty.name AS data_type,
    TYPE_NAME(c.system_type_id) AS base_type,
    c.max_length,
    c.is_nullable,
    c.is_computed,
    c.is_hidden,
    c.encryption_type_desc,
    c.generated_always_type_desc
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    v.name AS view_name,
    v.object_id,
    m.definition
FROM sys.views AS v
JOIN sys.schemas AS s ON s.schema_id = v.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = v.object_id
ORDER BY s.name, v.name;

SELECT
    s.name AS schema_name,
    tr.name AS trigger_name,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
    OBJECT_NAME(tr.parent_id) AS parent_object,
    tr.is_disabled,
    m.definition
FROM sys.triggers AS tr
LEFT JOIN sys.objects AS o ON o.object_id = tr.object_id
LEFT JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = tr.object_id
ORDER BY tr.name;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms AS sn
JOIN sys.schemas AS s ON s.schema_id = sn.schema_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    p.name AS policy_name,
    p.is_enabled,
    pr.predicate_type_desc,
    pr.operation_desc,
    pr.predicate_definition
FROM sys.security_predicates AS pr
JOIN sys.security_policies AS p ON p.object_id = pr.object_id
JOIN sys.tables AS t ON t.object_id = pr.target_object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

SELECT
    USER_NAME() AS database_user,
    IS_MEMBER(N'db_owner') AS is_db_owner,
    HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION') AS can_view_definition,
    HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'SELECT') AS can_select_database,
    HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CONTROL') AS has_control_database;
