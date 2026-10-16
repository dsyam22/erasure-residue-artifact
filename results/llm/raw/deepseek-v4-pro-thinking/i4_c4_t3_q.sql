SELECT 
    DB_NAME() AS database_name,
    SERVERPROPERTY('ProductVersion') AS product_version;

SELECT 
    o.object_id,
    s.name AS schema_name,
    o.name AS object_name,
    o.type,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('U','V')
ORDER BY s.name, o.name;

SELECT 
    t.object_id,
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type,
    t.temporal_type_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables ht ON t.history_table_id = ht.object_id
LEFT JOIN sys.schemas hs ON ht.schema_id = hs.schema_id
ORDER BY s.name, t.name;

SELECT 
    c.object_id,
    OBJECT_SCHEMA_NAME(c.object_id) AS schema_name,
    OBJECT_NAME(c.object_id) AS object_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type_desc
FROM sys.columns c
JOIN sys.objects o ON c.object_id = o.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE o.type IN ('U','V')
ORDER BY OBJECT_SCHEMA_NAME(c.object_id), OBJECT_NAME(c.object_id), c.column_id;

SELECT 
    p.object_id,
    OBJECT_SCHEMA_NAME(p.object_id) AS schema_name,
    OBJECT_NAME(p.object_id) AS object_name,
    p.partition_number,
    p.rows
FROM sys.partitions p
JOIN sys.objects o ON p.object_id = o.object_id
WHERE o.type IN ('U','V')
  AND p.index_id IN (0, 1)
ORDER BY OBJECT_SCHEMA_NAME(p.object_id), OBJECT_NAME(p.object_id), p.partition_number;
