SELECT 
    DB_NAME() AS database_name,
    d.compatibility_level,
    d.state_desc,
    d.is_read_only,
    d.create_date
FROM sys.databases d
WHERE d.name = DB_NAME();

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type,
    t.temporal_type_desc,
    t.history_table_id,
    hss.name AS history_schema_name,
    hst.name AS history_table_name,
    t.ledger_type,
    t.ledger_type_desc,
    t.is_external,
    t.is_filetable,
    ps.rows AS row_count,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type,
    c.generated_always_type_desc,
    c.is_rowguidcol,
    c.encryption_type,
    c.encryption_type_desc,
    c.collation_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.tables hst ON t.history_table_id = hst.object_id
LEFT JOIN sys.schemas hss ON hst.schema_id = hss.schema_id
LEFT JOIN (
    SELECT object_id, SUM(rows) AS rows
    FROM sys.partitions
    WHERE index_id IN (0,1)
    GROUP BY object_id
) ps ON ps.object_id = t.object_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    o.object_id,
    s.name AS schema_name,
    o.name AS object_name,
    o.type,
    o.type_desc,
    o.create_date,
    o.modify_date
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
ORDER BY o.type, s.name, o.name;

SELECT
    v.object_id,
    s.name AS schema_name,
    v.name AS view_name,
    i.index_id,
    i.name AS index_name,
    i.type,
    i.type_desc,
    i.is_unique,
    i.is_disabled,
    ps.rows AS row_count
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
JOIN sys.indexes i ON v.object_id = i.object_id
LEFT JOIN (
    SELECT object_id, index_id, SUM(rows) AS rows
    FROM sys.partitions
    GROUP BY object_id, index_id
) ps ON ps.object_id = v.object_id AND ps.index_id = i.index_id
WHERE i.index_id > 0
ORDER BY s.name, v.name, i.index_id;

SELECT
    tr.object_id,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
    OBJECT_NAME(tr.parent_id) AS parent_name,
    tr.name AS trigger_name,
    tr.is_instead_of_trigger,
    tr.is_disabled,
    OBJECT_DEFINITION(tr.object_id) AS trigger_definition
FROM sys.triggers tr
WHERE tr.is_ms_shipped = 0
ORDER BY parent_schema, parent_name, tr.name;

SELECT
    p.object_id,
    OBJECT_SCHEMA_NAME(p.object_id) AS schema_name,
    OBJECT_NAME(p.object_id) AS object_name,
    p.name AS period_name,
    p.period_type,
    p.period_type_desc,
    p.start_column_id,
    p.end_column_id
FROM sys.periods p
ORDER BY schema_name, object_name, p.name;

SELECT 
    fk.object_id,
    fk.name AS foreign_key_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS parent_schema,
    OBJECT_NAME(fk.parent_object_id) AS parent_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    fk.is_disabled,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys fk
WHERE fk.is_ms_shipped = 0
ORDER BY parent_schema, parent_table, fk.name;
