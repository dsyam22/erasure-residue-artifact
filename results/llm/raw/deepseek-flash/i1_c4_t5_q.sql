SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.schemas AS s
JOIN sys.tables AS t
    ON t.schema_id = s.schema_id
JOIN sys.columns AS c
    ON c.object_id = t.object_id
JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o
    ON o.object_id = m.object_id
JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    i.has_filter,
    i.filter_definition
FROM sys.indexes AS i
JOIN sys.tables AS t
    ON t.object_id = i.object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE i.type > 0
ORDER BY s.name, t.name, i.index_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
JOIN sys.partitions AS p
    ON p.object_id = t.object_id
   AND p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT
    name,
    database_id,
    source_database_id,
    is_read_only,
    is_auto_close_on,
    state_desc,
    snapshot_isolation_state_desc,
    is_read_committed_snapshot_on,
    recovery_model_desc,
    log_reuse_wait_desc,
    is_cdc_enabled,
    is_published,
    is_distributor,
    is_merge_published,
    is_sync_with_backup,
    is_encrypted,
    is_trustworthy_on,
    is_db_chaining_on,
    containment_desc,
    compatibility_level,
    collation_name
FROM sys.databases
ORDER BY name;

SELECT
    DB_NAME() AS current_database,
    SUSER_SNAME() AS login_name,
    USER_NAME() AS database_user,
    IS_SRVROLEMEMBER('sysadmin') AS is_sysadmin,
    IS_MEMBER('db_owner') AS is_db_owner,
    IS_MEMBER('db_datawriter') AS is_db_datawriter,
    IS_MEMBER('db_datareader') AS is_db_datareader;

SELECT
    name,
    value,
    value_in_use,
    description
FROM sys.configurations
WHERE name IN ('clr enabled', 'Ad Hoc Distributed Queries', 'Ole Automation Procedures', 'xp_cmdshell');

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects AS o
JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
WHERE o.type IN ('P', 'FN', 'IF', 'TF', 'TR', 'V')
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
JOIN sys.columns AS c
    ON c.object_id = t.object_id
JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
WHERE c.name IN ('customer_id', 'full_name', 'email', 'phone')
   OR ty.name IN ('nvarchar', 'varchar', 'text', 'ntext')
ORDER BY s.name, t.name, c.column_id;
