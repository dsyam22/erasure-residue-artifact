-- Current database and relevant options
SELECT 
    d.name AS database_name,
    d.database_id,
    d.compatibility_level,
    d.collation_name,
    d.is_read_only,
    d.recovery_model_desc,
    d.snapshot_isolation_state_desc,
    d.is_read_committed_snapshot_on,
    d.is_cdc_enabled,
    d.is_encrypted,
    d.is_temporal_history_retention_enabled,
    d.is_trustworthy_on,
    d.is_broker_enabled
FROM sys.databases d
WHERE d.database_id = DB_ID();

-- Change Tracking database settings (if enabled)
SELECT 
    ct.database_id,
    ct.is_auto_cleanup_on,
    ct.retention_period,
    ct.retention_period_units_desc
FROM sys.change_tracking_databases ct
WHERE ct.database_id = DB_ID();

-- User object inventory and counts
SELECT 
    s.name AS schema_name,
    o.type_desc,
    COUNT(*) AS object_count
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
GROUP BY s.name, o.type_desc
ORDER BY s.name, o.type_desc;

-- User tables / temporal / CDC / change tracking / row counts
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.is_memory_optimized,
    t.is_external,
    t.is_node,
    t.is_edge,
    t.durability_desc,
    t.is_tracked_by_cdc,
    ct.is_tracked_by_auto_capture,
    ct.is_tracked_by_auto_cleanup,
    ps.row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.objects o ON t.object_id = o.object_id
LEFT JOIN sys.change_tracking_tables ct ON t.object_id = ct.object_id
LEFT JOIN (
    SELECT object_id, SUM(row_count) AS row_count
    FROM sys.dm_db_partition_stats
    WHERE index_id IN (0,1)
    GROUP BY object_id
) ps ON t.object_id = ps.object_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, t.name;

-- Columns of user tables
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.generated_always_type_desc,
    c.encryption_type_desc,
    c.is_sparse,
    c.is_column_set,
    c.is_computed,
    cc.definition AS computed_definition
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.objects o ON t.object_id = o.object_id
JOIN sys.columns c ON t.object_id = c.object_id
LEFT JOIN sys.computed_columns cc ON c.object_id = cc.object_id AND c.column_id = cc.column_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

-- Temporal periods
SELECT 
    OBJECT_SCHEMA_NAME(p.object_id) AS schema_name,
    OBJECT_NAME(p.object_id) AS table_name,
    p.name AS period_name,
    p.period_type_desc,
    p.start_column_id,
    p.end_column_id
FROM sys.periods p
ORDER BY schema_name, table_name, p.period_type_desc;

-- Views
SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    v.has_opaque_metadata,
    v.is_date_correlation_view,
    v.with_check_option,
    v.is_replicated,
    v.is_tracked_by_cdc,
    m.definition
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
JOIN sys.objects o ON v.object_id = o.object_id
LEFT JOIN sys.sql_modules m ON v.object_id = m.object_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, v.name;

-- Triggers
SELECT 
    tr.name AS trigger_name,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
    OBJECT_NAME(tr.parent_id) AS parent_name,
    tr.is_disabled,
    tr.is_instead_of_trigger,
    tr.is_ms_shipped,
    m.definition
FROM sys.triggers tr
LEFT JOIN sys.sql_modules m ON tr.object_id = m.object_id
ORDER BY parent_schema, parent_name, tr.name;

-- Stored procedures and functions (user modules)
SELECT 
    s.name AS schema_name,
    o.name AS module_name,
    o.type_desc,
    m.definition
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
LEFT JOIN sys.sql_modules m ON o.object_id = m.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('P','PC','FN','IF','TF','FS','FT','AF','X')
ORDER BY o.type_desc, s.name, o.name;

-- Synonyms
SELECT 
    s.name AS schema_name,
    syn.name AS synonym_name,
    syn.base_object_name
FROM sys.synonyms syn
JOIN sys.schemas s ON syn.schema_id = s.schema_id
ORDER BY s.name, syn.name;

-- Indexes
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    i.has_filter,
    i.filter_definition
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.objects o ON t.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND i.type > 0
ORDER BY s.name, t.name, i.index_id;

-- Full-text indexes
SELECT 
    OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS fulltext_index_name,
    c.name AS fulltext_catalog_name,
    i.is_enabled,
    i.change_tracking_state_desc
FROM sys.fulltext_indexes i
JOIN sys.fulltext_catalogs c ON i.fulltext_catalog_id = c.fulltext_catalog_id
ORDER BY schema_name, table_name;

-- Dynamic data masking
SELECT 
    OBJECT_SCHEMA_NAME(mc.object_id) AS schema_name,
    OBJECT_NAME(mc.object_id) AS table_name,
    c.name AS column_name,
    mc.masking_function
FROM sys.masked_columns mc
JOIN sys.columns c ON mc.object_id = c.object_id AND mc.column_id = c.column_id
ORDER BY schema_name, table_name, column_name;

-- Foreign keys
SELECT 
    fk.name AS foreign_key_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS parent_schema,
    OBJECT_NAME(fk.parent_object_id) AS parent_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc,
    fk.is_disabled
FROM sys.foreign_keys fk
ORDER BY parent_schema, parent_table, fk.name;
