SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    CASE WHEN c.is_computed = 1 THEN cc.definition ELSE NULL END AS computed_definition,
    dc.definition AS default_definition
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.computed_columns AS cc ON cc.object_id = c.object_id AND cc.column_id = c.column_id
LEFT JOIN sys.default_constraints AS dc ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
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
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')
  AND (o.name LIKE '%customer%' OR o.name LIKE '%replica%' OR o.name LIKE '%subject%')
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    i.is_unique,
    i.is_primary_key,
    i.has_filter,
    i.filter_definition
FROM sys.indexes AS i
JOIN sys.tables AS t ON t.object_id = i.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name IN ('dbo', 'reporting')
  AND t.name IN ('customer', 'customer_replica')
ORDER BY s.name, t.name, i.index_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS total_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE s.name IN ('dbo', 'reporting')
  AND t.name IN ('customer', 'customer_replica')
GROUP BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.name IN ('customer_id', 'full_name', 'email', 'phone')
  AND s.name IN ('dbo', 'reporting')
ORDER BY s.name, t.name, c.name;
