SELECT
    s.name                    AS schema_name,
    t.name                    AS table_name,
    t.type_desc               AS table_type,
    t.temporal_type_desc      AS temporal_type,
    t.is_tracked_by_cdc,
    t.is_filetable,
    t.is_memory_optimized,
    t.ledger_type_desc
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

SELECT
    s.name                      AS schema_name,
    t.name                      AS table_name,
    c.column_id,
    c.name                      AS column_name,
    TYPE_NAME(c.user_type_id)   AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type_desc,
    c.is_hidden
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name                    AS schema_name,
    t.name                    AS table_name,
    t.temporal_type_desc      AS temporal_type,
    OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
    OBJECT_NAME(t.history_table_id)        AS history_table
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.temporal_type <> 0
ORDER BY s.name, t.name;

SELECT
    s.name          AS schema_name,
    t.name          AS table_name,
    p.partition_number,
    p.rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, p.partition_number;

SELECT
    fk.name                     AS foreign_key_name,
    ps.name                     AS parent_schema,
    pt.name                     AS parent_table,
    pc.name                     AS parent_column,
    rs.name                     AS referenced_schema,
    rt.name                     AS referenced_table,
    rc.name                     AS referenced_column
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables AS pt ON fkc.parent_object_id = pt.object_id
JOIN sys.schemas AS ps ON pt.schema_id = ps.schema_id
JOIN sys.columns AS pc ON fkc.parent_object_id = pc.object_id AND fkc.parent_column_id = pc.column_id
JOIN sys.tables AS rt ON fkc.referenced_object_id = rt.object_id
JOIN sys.schemas AS rs ON rt.schema_id = rs.schema_id
JOIN sys.columns AS rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
ORDER BY fk.name;

SELECT
    tr.name                     AS trigger_name,
    s.name                      AS schema_name,
    t.name                      AS table_name,
    tr.is_disabled,
    tr.is_instead_of_trigger
FROM sys.triggers AS tr
JOIN sys.tables AS t ON tr.parent_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE tr.parent_class = 1
ORDER BY s.name, t.name, tr.name;
