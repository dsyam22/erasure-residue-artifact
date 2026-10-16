SELECT 
    DB_NAME()                           AS database_name,
    s.name                              AS schema_name,
    t.name                              AS table_name,
    ps.row_count,
    t.temporal_type_desc,
    hs.name                             AS history_schema_name,
    ht.name                             AS history_table_name,
    t.create_date,
    t.modify_date
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables ht ON t.history_table_id = ht.object_id
LEFT JOIN sys.schemas hs ON ht.schema_id = hs.schema_id
CROSS APPLY (
    SELECT SUM(p.rows) AS row_count
    FROM sys.partitions p
    WHERE p.object_id = t.object_id
      AND p.index_id IN (0, 1)
) ps
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

SELECT 
    s.name                              AS schema_name,
    o.name                              AS object_name,
    o.type_desc                         AS object_type,
    c.column_id,
    c.name                              AS column_name,
    ty.name                             AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.columns c ON o.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE o.type IN ('U','V')
  AND o.is_ms_shipped = 0
ORDER BY s.name, o.name, c.column_id;
