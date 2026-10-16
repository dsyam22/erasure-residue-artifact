SELECT 
    d.name AS database_name,
    d.compatibility_level,
    d.collation_name,
    d.state_desc,
    d.recovery_model_desc,
    d.is_cdc_enabled,
    ctd.is_auto_cleanup_on AS change_tracking_auto_cleanup,
    ctd.retention_period AS change_tracking_retention_period,
    ctd.retention_period_units_desc AS change_tracking_retention_units
FROM sys.databases d
LEFT JOIN sys.change_tracking_databases ctd ON ctd.database_id = d.database_id
WHERE d.name = DB_NAME();

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    t.temporal_type_desc,
    t.history_table_name,
    COALESCE(SUM(p.rows), 0) AS row_count
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
LEFT JOIN sys.tables t ON t.object_id = o.object_id
LEFT JOIN sys.partitions p ON p.object_id = o.object_id AND p.index_id IN (0,1)
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
GROUP BY s.name, o.name, o.type_desc, t.temporal_type_desc, t.history_table_name
ORDER BY o.type_desc, s.name, o.name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    cc.definition AS computed_column_definition,
    c.collation_name,
    c.generated_always_type_desc,
    c.is_hidden,
    c.encryption_type_desc
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.columns c ON c.object_id = o.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.computed_columns cc ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
ORDER BY o.type_desc, s.name, o.name, c.column_id;
