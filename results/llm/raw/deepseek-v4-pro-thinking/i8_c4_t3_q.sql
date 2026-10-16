SELECT 
    DB_NAME() AS database_name,
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.columns c ON o.object_id = c.object_id
WHERE o.type IN ('U','V')
  AND o.is_ms_shipped = 0
ORDER BY s.name, o.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
  AND t.is_ms_shipped = 0
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.columns c ON o.object_id = c.object_id
WHERE o.type IN ('U','V')
  AND o.is_ms_shipped = 0
  AND TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar','text','ntext','xml')
ORDER BY s.name, o.name, c.column_id;
