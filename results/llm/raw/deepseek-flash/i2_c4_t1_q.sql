SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.name AS column_name,
    t.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS t ON t.user_type_id = c.user_type_id
WHERE o.type IN ('U', 'V')
  AND (
        c.name LIKE '%customer%'
     OR c.name LIKE '%full%name%'
     OR c.name LIKE '%email%'
     OR c.name LIKE '%phone%'
     OR c.name LIKE '%subject%'
     OR o.name LIKE '%customer%'
     OR o.name LIKE '%audit%'
     OR o.name LIKE '%log%'
     OR o.name LIKE '%history%'
     OR o.name LIKE '%archive%'
     OR o.name LIKE '%backup%'
     OR o.name LIKE '%temp%'
      )
ORDER BY s.name, o.name, c.column_id;
