SELECT
    s.name                       AS schema_name,
    t.name                       AS table_name,
    t.object_id,
    t.is_ms_shipped,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    t.lob_data_space_id,
    SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END) AS row_count,
    STRING_AGG(
        CASE WHEN ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml')
             THEN c.name + ' (' + ty.name + ')' END, ', ')            AS text_columns,
    STRING_AGG(CAST(c.name AS nvarchar(256)), ', ')                  AS all_columns
FROM sys.tables t
JOIN sys.schemas s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.columns c
    ON c.object_id = t.object_id
LEFT JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.dm_db_partition_stats ps
    ON ps.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.is_ms_shipped,
         t.temporal_type_desc, t.is_tracked_by_cdc, t.lob_data_space_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    v.name AS view_name,
    m.definition
FROM sys.views v
JOIN sys.schemas s
    ON s.schema_id = v.schema_id
LEFT JOIN sys.sql_modules m
    ON m.object_id = v.object_id
WHERE v.is_ms_shipped = 0;

SELECT
    OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
    o.name                          AS object_name,
    o.type_desc
FROM sys.objects o
WHERE o.type IN ('TR','P','FN','IF','TF','SO')
  AND o.is_ms_shipped = 0;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.is_memory_optimized
FROM sys.tables t
JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND (t.is_memory_optimized = 1 OR t.is_filetable = 1 OR t.is_external = 1);
