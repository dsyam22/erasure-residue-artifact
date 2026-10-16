SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    cc.definition AS computed_definition,
    c.collation_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON t.object_id = c.object_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.computed_columns AS cc 
    ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN sys.partitions AS p 
    ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables AS ht ON t.history_table_id = ht.object_id
LEFT JOIN sys.schemas AS hs ON ht.schema_id = hs.schema_id
WHERE t.is_ms_shipped = 0
  AND t.temporal_type = 2
ORDER BY s.name, t.name;
