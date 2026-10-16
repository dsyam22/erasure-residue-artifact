SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_identity,
    c.is_computed
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE s.name IN ('dbo', 'reporting')
  AND t.name IN ('customer', 'customer_replica')
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint,
    COL_NAME(ic.object_id, ic.column_id) AS column_name,
    ic.key_ordinal,
    ic.is_included_column
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.indexes AS i ON i.object_id = t.object_id
JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
WHERE s.name IN ('dbo', 'reporting')
  AND t.name IN ('customer', 'customer_replica')
ORDER BY s.name, t.name, i.index_id, ic.key_ordinal, ic.index_column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer_replica%'
   OR m.definition LIKE '%subject42%'
   OR m.definition LIKE '%Subject_0000042%'
   OR m.definition LIKE '%subject42@example.invalid%'
   OR m.definition LIKE '%0000042%';

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE s.name IN ('dbo', 'reporting')
  AND t.name IN ('customer', 'customer_replica')
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
