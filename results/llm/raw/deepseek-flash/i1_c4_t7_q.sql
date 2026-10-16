SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.column_id,
    c.name AS column_name,
    t.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_identity,
    c.is_computed
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.columns c ON c.object_id = o.object_id
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE o.type IN ('U', 'V')
  AND (
      c.name LIKE '%customer%'
      OR c.name LIKE '%name%'
      OR c.name LIKE '%email%'
      OR c.name LIKE '%phone%'
      OR c.name LIKE '%mail%'
      OR c.name LIKE '%contact%'
      OR c.name LIKE '%subject%'
      OR c.name LIKE '%person%'
      OR o.name LIKE '%customer%'
      OR o.name LIKE '%subject%'
      OR o.name LIKE '%person%'
  )
ORDER BY s.name, o.name, c.column_id;
