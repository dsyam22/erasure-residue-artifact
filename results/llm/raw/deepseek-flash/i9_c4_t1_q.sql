SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'customer'
ORDER BY c.column_id;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    o.object_id
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')
ORDER BY o.type_desc, s.name, o.name;

SELECT 
    i.name AS index_name,
    i.type_desc,
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ic.key_ordinal,
    ic.is_included_column
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.name = 'customer'
ORDER BY i.name, ic.key_ordinal;

SELECT 
    name AS trigger_name,
    OBJECT_NAME(parent_id) AS parent_object,
    is_disabled,
    is_instead_of_trigger
FROM sys.triggers;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY row_count DESC;

SELECT 
    name AS server_audit_name,
    type_desc,
    is_state_enabled
FROM sys.server_audits;

SELECT 
    name AS database_audit_spec_name,
    is_state_enabled
FROM sys.database_audit_specifications;

SELECT 
    name AS audit_spec_name,
    is_state_enabled
FROM sys.server_audit_specifications;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.name IN ('customer_id','full_name','email','phone')
  AND t.name <> 'customer'
ORDER BY s.name, t.name, c.name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%full_name%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%';

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name LIKE '%customer%'
   OR t.name LIKE '%history%'
   OR t.name LIKE '%audit%'
   OR t.name LIKE '%log%'
   OR t.name LIKE '%archive%'
ORDER BY s.name, t.name, c.name;

SELECT 
    name AS database_name,
    state_desc,
    recovery_model_desc,
    is_read_committed_snapshot_on,
    snapshot_isolation_state_desc
FROM sys.databases
WHERE name = 'llm_i9';

SELECT 
    name AS file_name,
    type_desc,
    physical_name,
    size,
    max_size,
    growth
FROM sys.database_files;

SELECT 
    name AS cdc_capture_instance,
    capture_instance,
    is_tracked_by_cdc
FROM sys.tables t
WHERE is_tracked_by_cdc = 1;

SELECT 
    name AS change_tracking_table,
    is_track_columns_updated_on
FROM sys.tables
WHERE is_tracked_by_change_tracking = 1;

SELECT 
    name AS temporal_table,
    temporal_type_desc,
    history_table_id,
    OBJECT_NAME(history_table_id) AS history_table_name
FROM sys.tables
WHERE temporal_type <> 0;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar','varchar','nchar','char','ntext','text')
  AND t.name <> 'customer'
ORDER BY s.name, t.name, c.name;

SELECT 
    name AS linked_server_name,
    product,
    provider,
    data_source
FROM sys.servers
WHERE is_linked = 1;

SELECT 
    name AS synonym_name,
    base_object_name
FROM sys.synonyms;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('U','V')
  AND o.name LIKE '%backup%'
   OR o.name LIKE '%restore%'
   OR o.name LIKE '%temp%'
   OR o.name LIKE '%staging%'
ORDER BY s.name, o.name;
