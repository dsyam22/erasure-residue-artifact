SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, t.is_memory_optimized
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml')
   OR c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%' OR c.name LIKE '%subject%'
ORDER BY s.name, t.name, c.column_id;

SELECT
    OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
    o.name AS object_name,
    o.type_desc,
    OBJECT_SCHEMA_NAME(d.referenced_id) AS referenced_schema,
    OBJECT_NAME(d.referenced_id) AS referenced_object
FROM sys.objects o
LEFT JOIN sys.sql_expression_dependencies d ON d.referencing_id = o.object_id
WHERE o.type IN ('V','TR','P','FN','IF','TF')
  AND (d.referenced_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('reporting.customer_replica'))
       OR o.type = 'TR')
ORDER BY schema_name, object_name;

SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    fk.name AS fk_name
FROM sys.foreign_keys fk
WHERE fk.referenced_object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('reporting.customer_replica'));
