SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.is_memory_optimized,
    t.is_tracked_by_cdc,
    t.is_ms_shipped,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_row_count,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.columns AS c
    ON c.object_id = t.object_id
   AND TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname')
LEFT JOIN sys.partitions AS p
    ON p.object_id = t.object_id
GROUP BY
    s.name, t.name, t.object_id, t.temporal_type_desc, t.is_memory_optimized,
    t.is_tracked_by_cdc, t.is_ms_shipped, c.column_id, c.name, c.user_type_id,
    c.max_length, c.is_nullable
ORDER BY s.name, t.name, c.column_id;
