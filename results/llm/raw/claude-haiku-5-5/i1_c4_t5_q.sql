SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    SUM(ps.row_count) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.dm_db_partition_stats ps
    ON ps.object_id = t.object_id AND ps.index_id IN (0, 1)
WHERE ty.name IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext', 'xml', 'sysname')
   OR c.name LIKE '%email%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%name%'
   OR t.name LIKE '%audit%'
   OR t.name LIKE '%log%'
   OR t.name LIKE '%stage%'
   OR t.name LIKE '%customer%'
   OR t.name LIKE '%history%'
   OR t.name LIKE '%backup%'
GROUP BY s.name, t.name, c.name, ty.name, c.max_length, c.is_nullable
ORDER BY s.name, t.name, c.column_id;
