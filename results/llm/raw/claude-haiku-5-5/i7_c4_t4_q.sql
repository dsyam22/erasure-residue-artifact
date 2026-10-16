SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       t.is_tracked_by_cdc,
       t.is_ms_shipped,
       SUM(p.rows) AS approx_row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY s.name, t.name, t.temporal_type_desc, t.is_tracked_by_cdc, t.is_ms_shipped
ORDER BY s.name, t.name;

SELECT s.name AS schema_name,
       o.name AS table_name,
       c.name AS column_name,
       ty.name AS data_type,
       c.max_length
FROM sys.columns AS c
JOIN sys.objects AS o ON o.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE o.type IN ('U', 'V')
  AND (c.name LIKE '%name%'
    OR c.name LIKE '%mail%'
    OR c.name LIKE '%phone%'
    OR c.name LIKE '%cust%'
    OR c.name LIKE '%subject%'
    OR c.name LIKE '%person%'
    OR c.name LIKE '%contact%'
    OR c.name LIKE '%json%'
    OR c.name LIKE '%note%'
    OR c.name LIKE '%text%'
    OR c.name LIKE '%payload%')
ORDER BY s.name, o.name, c.column_id;

SELECT s.name AS schema_name,
       tr.name AS trigger_name,
       OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
       OBJECT_NAME(tr.parent_id) AS parent_table,
       tr.is_disabled
FROM sys.triggers AS tr
JOIN sys.objects AS o ON o.object_id = tr.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE tr.is_ms_shipped = 0;

SELECT o.type_desc,
       s.name AS schema_name,
       o.name AS object_name
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('P', 'FN', 'IF', 'TF', 'V')
  AND o.is_ms_shipped = 0
ORDER BY s.name, o.name;
