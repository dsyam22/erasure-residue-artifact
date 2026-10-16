SELECT DB_NAME() AS database_name;

SELECT s.name AS schema_name,
       t.name AS table_name,
       t.type_desc,
       t.create_date,
       t.modify_date
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

SELECT s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length,
       c.precision,
       c.scale,
       c.is_nullable,
       c.is_computed,
       c.is_identity,
       c.column_id
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT s.name AS schema_name,
       t.name AS table_name,
       SUM(p.rows) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.partitions AS p ON t.object_id = p.object_id
WHERE t.is_ms_shipped = 0
  AND p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT s.name AS schema_name,
       sy.name AS synonym_name,
       sy.base_object_name
FROM sys.synonyms AS sy
JOIN sys.schemas AS s ON sy.schema_id = s.schema_id
ORDER BY s.name, sy.name;

SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       m.definition
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON m.object_id = o.object_id
JOIN sys.schemas AS s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
ORDER BY o.type_desc, s.name, o.name;
