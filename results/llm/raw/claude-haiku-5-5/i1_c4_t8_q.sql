SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.is_ms_shipped,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    t.lob_data_space_id,
    p.row_count,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.columns AS c
    ON c.object_id = t.object_id
LEFT JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
LEFT JOIN (
    SELECT object_id, SUM(rows) AS row_count
    FROM sys.partitions
    WHERE index_id IN (0, 1)
    GROUP BY object_id
) AS p
    ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0

UNION ALL

SELECT
    'FK' AS schema_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS table_name,
    NULL, NULL, NULL, NULL, NULL,
    fk.name AS column_name,
    CONCAT('references ', OBJECT_SCHEMA_NAME(fk.referenced_object_id), '.', OBJECT_NAME(fk.referenced_object_id)) AS data_type,
    NULL, NULL
FROM sys.foreign_keys AS fk

UNION ALL

SELECT
    'FULLTEXT' AS schema_name,
    OBJECT_SCHEMA_NAME(fti.object_id) AS table_name,
    NULL, NULL, NULL, NULL, NULL,
    'fulltext_index' AS column_name,
    'catalog present' AS data_type,
    NULL, NULL
FROM sys.fulltext_indexes AS fti

ORDER BY schema_name, table_name, column_name;
