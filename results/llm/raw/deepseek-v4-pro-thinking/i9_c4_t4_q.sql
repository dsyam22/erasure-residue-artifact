SELECT 
    DB_NAME() AS database_name,
    @@SERVERNAME AS server_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    SERVERPROPERTY('Edition') AS edition;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.type_desc,
    t.temporal_type,
    t.temporal_type_desc,
    t.ledger_type,
    t.ledger_type_desc,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.durability_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables AS ht ON t.history_table_id = ht.object_id
LEFT JOIN sys.schemas AS hs ON ht.schema_id = hs.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type_desc,
    c.is_hidden,
    c.encryption_type_desc,
    c.collation_name
FROM sys.columns AS c
JOIN sys.tables AS t ON c.object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    p.name AS period_name,
    p.period_type_desc,
    cs.name AS period_start_column,
    ce.name AS period_end_column
FROM sys.periods AS p
JOIN sys.tables AS t ON p.object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS cs ON p.object_id = cs.object_id AND p.start_column_id = cs.column_id
JOIN sys.columns AS ce ON p.object_id = ce.object_id AND p.end_column_id = ce.column_id
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    i.is_disabled,
    i.filter_definition,
    c.name AS column_name,
    ic.key_ordinal,
    ic.is_included_column,
    ic.is_descending_key
FROM sys.indexes AS i
JOIN sys.tables AS t ON i.object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
LEFT JOIN sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.is_ms_shipped = 0
  AND i.type > 0
ORDER BY s.name, t.name, i.name, ic.key_ordinal, ic.index_column_id;

SELECT 
    fk.name AS foreign_key_name,
    ps.name AS parent_schema,
    pt.name AS parent_table,
    pc.name AS parent_column,
    fkc.constraint_column_id,
    rs.name AS referenced_schema,
    rt.name AS referenced_table,
    rc.name AS referenced_column
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables AS pt ON fk.parent_object_id = pt.object_id
JOIN sys.schemas AS ps ON pt.schema_id = ps.schema_id
JOIN sys.tables AS rt ON fk.referenced_object_id = rt.object_id
JOIN sys.schemas AS rs ON rt.schema_id = rs.schema_id
JOIN sys.columns AS pc ON fkc.parent_object_id = pc.object_id AND fkc.parent_column_id = pc.column_id
JOIN sys.columns AS rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
WHERE pt.is_ms_shipped = 0 OR rt.is_ms_shipped = 0
ORDER BY ps.name, pt.name, fk.name, fkc.constraint_column_id;

SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    v.object_id,
    v.type_desc,
    m.is_schema_bound,
    m.definition
FROM sys.views AS v
JOIN sys.schemas AS s ON v.schema_id = s.schema_id
LEFT JOIN sys.sql_modules AS m ON v.object_id = m.object_id
WHERE v.is_ms_shipped = 0
ORDER BY s.name, v.name;
