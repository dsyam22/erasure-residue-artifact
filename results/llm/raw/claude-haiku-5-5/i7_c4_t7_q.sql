SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    p.row_count,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable,
    CASE WHEN c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
              OR c.name LIKE '%customer%' OR c.name LIKE '%subject%'
              OR c.name LIKE '%person%' OR c.name LIKE '%addr%'
         THEN 1 ELSE 0 END AS looks_personal
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.columns AS c
    ON c.object_id = t.object_id
LEFT JOIN (
    SELECT object_id, SUM(row_count) AS row_count
    FROM sys.dm_db_partition_stats
    WHERE index_id IN (0, 1)
    GROUP BY object_id
) AS p
    ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    fk.name AS fk_name,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys AS fk
ORDER BY parent_schema, parent_table;

SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS object_schema,
    OBJECT_NAME(m.object_id) AS object_name,
    o.type_desc
FROM sys.sql_modules AS m
JOIN sys.objects AS o
    ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
ORDER BY object_schema, object_name;
