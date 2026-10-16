SELECT 
    DB_NAME() AS database_name,
    o.type_desc AS object_type,
    s.name AS schema_name,
    o.name AS object_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    t.temporal_type,
    t.temporal_type_desc,
    hs.name AS history_table_schema,
    h.name AS history_table_name,
    t.is_tracked_by_cdc,
    p.row_count
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.columns c ON c.object_id = o.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.tables t ON t.object_id = o.object_id
LEFT JOIN sys.tables h ON h.object_id = t.history_table_id
LEFT JOIN sys.schemas hs ON hs.schema_id = h.schema_id
OUTER APPLY (
    SELECT SUM(part.rows) AS row_count
    FROM sys.partitions part
    WHERE part.object_id = o.object_id
      AND part.index_id IN (0, 1)
) p
WHERE o.type IN ('U','V')
  AND o.is_ms_shipped = 0
ORDER BY o.type_desc, s.name, o.name, c.column_id;
