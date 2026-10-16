SELECT 
    DB_NAME() AS database_name,
    @@SERVERNAME AS server_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    CONVERT(nvarchar(128), DATABASEPROPERTYEX(DB_NAME(), 'Collation')) AS collation,
    CONVERT(nvarchar(128), DATABASEPROPERTYEX(DB_NAME(), 'Recovery')) AS recovery_model,
    d.compatibility_level,
    d.is_cdc_enabled,
    d.is_encrypted
FROM sys.databases d
WHERE d.name = DB_NAME();

SELECT
    t.object_id AS table_object_id,
    s.name AS schema_name,
    t.name AS table_name,
    t.type_desc,
    t.temporal_type,
    t.temporal_type_desc,
    h.name AS history_table_name,
    t.ledger_type,
    t.ledger_type_desc,
    t.is_dropped_ledger_table,
    t.is_tracked_by_cdc,
    t.is_external,
    t.is_filetable,
    t.is_memory_optimized,
    t.durability_desc,
    t.create_date,
    t.modify_date
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS type_name,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type,
    c.generated_always_type_desc,
    c.is_hidden,
    c.is_masked,
    c.encryption_type,
    c.encryption_type_desc
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS type_name,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_computed,
    c.is_hidden
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE s.name = 'cdc'
ORDER BY t.name, c.column_id;

SELECT
    o.type,
    o.type_desc,
    s.name AS schema_name,
    o.name AS object_name,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
ORDER BY o.type, s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    cc.definition
FROM sys.computed_columns cc
JOIN sys.columns c ON cc.object_id = c.object_id AND cc.column_id = c.column_id
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    syn.name AS synonym_name,
    syn.base_object_name
FROM sys.synonyms syn
JOIN sys.schemas s ON syn.schema_id = s.schema_id
ORDER BY s.name, syn.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.row_count) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.dm_db_partition_stats p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0 OR s.name = 'cdc'
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
