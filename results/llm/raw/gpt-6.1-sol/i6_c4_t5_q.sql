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
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.is_external,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    c.column_id,
    c.name AS column_name,
    ts.name AS type_schema_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_hidden,
    c.is_computed,
    c.is_filestream,
    c.encryption_type_desc,
    cc.definition AS computed_definition
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas AS hs ON hs.schema_id = ht.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
JOIN sys.schemas AS ts ON ts.schema_id = ty.schema_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.type IN ('V', 'P', 'FN', 'IF', 'TF', 'TR')
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
    SUM(p.rows) AS approximate_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id
WHERE p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT
    class_desc,
    major_id,
    minor_id,
    name AS property_name,
    value AS property_value
FROM sys.extended_properties;

SELECT
    permission_name,
    subentity_name
FROM sys.fn_my_permissions(NULL, 'DATABASE')
ORDER BY permission_name;
