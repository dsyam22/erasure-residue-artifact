SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.name AS column_name,
    t.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_computed,
    c.column_id
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.columns c ON o.object_id = c.object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE o.type IN ('U', 'V')
  AND (
      c.name LIKE '%customer%'
      OR c.name LIKE '%name%'
      OR c.name LIKE '%email%'
      OR c.name LIKE '%phone%'
      OR c.name LIKE '%subject%'
      OR o.name LIKE '%customer%'
      OR o.name LIKE '%subject%'
  )
ORDER BY s.name, o.name, c.column_id;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%full_name%'
   OR m.definition LIKE '%subject%';

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    i.is_unique,
    c.name AS column_name
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE c.name LIKE '%customer%'
   OR c.name LIKE '%email%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%name%'
ORDER BY s.name, t.name, i.name, ic.key_ordinal;

SELECT 
    name AS table_name,
    object_id
FROM sys.tables
ORDER BY name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')
ORDER BY s.name, o.name;
