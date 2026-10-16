SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND (
        c.name LIKE '%name%'
     OR c.name LIKE '%email%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%customer%'
     OR c.name LIKE '%member%'
     OR c.name LIKE '%subject%'
     OR c.name LIKE '%person%'
     OR c.name LIKE '%contact%'
      )
ORDER BY s.name, t.name, c.column_id;
