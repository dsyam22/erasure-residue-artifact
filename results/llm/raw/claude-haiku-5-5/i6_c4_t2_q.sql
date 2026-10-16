SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE m.definition LIKE N'%phone%';

SELECT
    OBJECT_SCHEMA_NAME(object_id) AS schema_name,
    OBJECT_NAME(object_id) AS object_name,
    name AS index_name,
    type_desc
FROM sys.indexes
WHERE name LIKE N'%phone%';

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN (N'xml', N'nvarchar', N'varchar', N'nchar', N'char', N'text', N'ntext', N'sysname')
  AND c.max_length > 0
ORDER BY s.name, t.name;

SELECT
    name AS table_name,
    is_memory_optimized,
    temporal_type_desc,
    is_ledger_table
FROM sys.tables
WHERE temporal_type <> 0 OR is_memory_optimized = 1 OR is_ledger_table = 1;

SELECT
    OBJECT_SCHEMA_NAME(parent_object_id) AS schema_name,
    OBJECT_NAME(parent_object_id) AS table_name,
    name AS trigger_name,
    OBJECT_DEFINITION(object_id) AS trigger_definition
FROM sys.triggers
WHERE is_ms_shipped = 0;

SELECT
    name AS query_store_status_db,
    is_query_store_on,
    is_cdc_enabled,
    is_change_tracking_on
FROM sys.databases
WHERE name = DB_NAME();
