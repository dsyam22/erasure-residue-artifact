-- QUERY
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.is_tracked_by_cdc,
    t.is_ms_shipped,
    c.name AS column_name,
    ty.name AS type_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.columns AS c ON c.object_id = t.object_id
LEFT JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND (
        t.is_tracked_by_cdc = 1
     OR c.name LIKE '%email%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%name%'
     OR c.name LIKE '%cust%'
     OR t.name LIKE '%cust%'
      )
ORDER BY s.name, t.name, c.column_id;
