SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    cc.definition AS computed_definition,
    dc.definition AS default_definition
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
JOIN sys.columns AS c
    ON c.object_id = t.object_id
JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id
   AND cc.column_id = c.column_id
LEFT JOIN sys.default_constraints AS dc
    ON dc.parent_object_id = c.object_id
   AND dc.parent_column_id = c.column_id
WHERE s.name IN ('dbo', 'reporting')
  AND t.name IN ('customer', 'customer_replica')
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    o.create_date,
    o.modify_date
FROM sys.objects AS o
JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
WHERE s.name IN ('dbo', 'reporting')
  AND o.type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')
ORDER BY s.name, o.type_desc, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint,
    i.has_filter,
    i.filter_definition
FROM sys.indexes AS i
JOIN sys.tables AS t
    ON t.object_id = i.object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE s.name IN ('dbo', 'reporting')
  AND t.name IN ('customer', 'customer_replica')
  AND i.type > 0
ORDER BY s.name, t.name, i.index_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    COUNT(*) AS row_count_estimate
FROM sys.dm_db_partition_stats AS ps
JOIN sys.tables AS t
    ON t.object_id = ps.object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE ps.index_id IN (0, 1)
  AND s.name IN ('dbo', 'reporting')
  AND t.name IN ('customer', 'customer_replica')
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
