SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    p.partition_rows_total
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
JOIN sys.columns AS c
    ON c.object_id = t.object_id
JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
OUTER APPLY (
    SELECT SUM(ps.row_count) AS partition_rows_total
    FROM sys.dm_db_partition_stats AS ps
    WHERE ps.object_id = t.object_id
      AND ps.index_id IN (0, 1)
) AS p
WHERE ty.name IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext', 'xml', 'sysname')
   OR c.name LIKE '%name%'
   OR c.name LIKE '%mail%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%cust%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
ORDER BY s.name, t.name, c.column_id;

SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    fk.name AS fk_name
FROM sys.foreign_keys AS fk
ORDER BY parent_schema, parent_table, child_schema, child_table;

SELECT
    OBJECT_SCHEMA_NAME(m.object_id) AS module_schema,
    OBJECT_NAME(m.object_id) AS module_name,
    o.type_desc
FROM sys.sql_modules AS m
JOIN sys.objects AS o
    ON o.object_id = m.object_id
WHERE m.definition LIKE '%customer%'
ORDER BY module_schema, module_name;
