SELECT 
    DB_NAME() AS database_name,
    SERVERPROPERTY('ServerName') AS server_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    SERVERPROPERTY('Edition') AS edition;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.type_desc,
    t.create_date,
    t.modify_date
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.collation_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON t.object_id = c.object_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.partitions AS p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
