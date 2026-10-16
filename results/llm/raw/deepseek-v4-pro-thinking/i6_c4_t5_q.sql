SELECT DB_NAME() AS database_name, collation_name
FROM sys.databases
WHERE database_id = DB_ID();

SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type,
       o.type_desc,
       o.create_date,
       o.modify_date
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V','P','FN','IF','TF','TR','PC')
ORDER BY o.type, s.name, o.name;

SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc AS object_type,
       c.column_id,
       c.name AS column_name,
       t.name AS data_type,
       c.max_length,
       c.precision,
       c.scale,
       c.is_nullable,
       c.is_computed,
       c.collation_name
FROM sys.columns c
JOIN sys.objects o ON c.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.types t ON c.system_type_id = t.user_type_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
ORDER BY s.name, o.name, c.column_id;

SELECT s.name AS schema_name,
       o.name AS object_name,
       c.name AS column_name,
       t.name AS data_type,
       c.max_length,
       c.collation_name
FROM sys.columns c
JOIN sys.objects o ON c.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.types t ON c.system_type_id = t.user_type_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
  AND (c.name LIKE '%phone%'
       OR c.name LIKE '%mobile%'
       OR c.name LIKE '%fax%'
       OR c.name LIKE '%tel%'
       OR c.name LIKE '%contact%')
ORDER BY s.name, o.name, c.name;

SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc AS object_type,
       m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
  AND (m.definition LIKE '%phone%'
       OR m.definition LIKE '%555-0000042%'
       OR m.definition LIKE '%5550000042%')
ORDER BY s.name, o.name;

SELECT s.name AS schema_name,
       o.name AS object_name,
       dc.name AS constraint_name,
       dc.type_desc AS constraint_type,
       dc.definition
FROM sys.default_constraints dc
JOIN sys.objects o ON dc.parent_object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE dc.definition LIKE '%phone%'
   OR dc.definition LIKE '%555%'
UNION ALL
SELECT s.name AS schema_name,
       o.name AS object_name,
       cc.name AS constraint_name,
       cc.type_desc AS constraint_type,
       cc.definition
FROM sys.check_constraints cc
JOIN sys.objects o ON cc.parent_object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE cc.definition LIKE '%phone%'
   OR cc.definition LIKE '%555%'
ORDER BY schema_name, object_name, constraint_name;

SELECT s.name AS schema_name,
       o.name AS object_name,
       c.name AS column_name,
       cc.definition AS computed_column_definition
FROM sys.computed_columns cc
JOIN sys.columns c ON cc.object_id = c.object_id AND cc.column_id = c.column_id
JOIN sys.objects o ON c.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE cc.definition LIKE '%phone%'
   OR cc.definition LIKE '%555%'
ORDER BY s.name, o.name, c.name;

SELECT s.name AS schema_name,
       o.name AS object_name,
       i.name AS index_name,
       i.filter_definition
FROM sys.indexes i
JOIN sys.objects o ON i.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE i.filter_definition IS NOT NULL
  AND (i.filter_definition LIKE '%phone%'
       OR i.filter_definition LIKE '%555%')
ORDER BY s.name, o.name, i.name;

SELECT s.name AS schema_name,
       o.name AS object_name,
       c.name AS column_name,
       ep.name AS property_name,
       ep.value AS property_value
FROM sys.extended_properties ep
JOIN sys.objects o ON ep.major_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
LEFT JOIN sys.columns c ON ep.minor_id = c.column_id AND ep.class = 1
WHERE CAST(ep.value AS nvarchar(4000)) LIKE '%phone%'
   OR CAST(ep.value AS nvarchar(4000)) LIKE '%555%'
ORDER BY s.name, o.name, c.name, ep.name;

SELECT s.name AS schema_name,
       o.name AS table_name,
       SUM(p.rows) AS row_count
FROM sys.partitions p
JOIN sys.objects o ON p.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type = 'U'
  AND p.index_id IN (0,1)
GROUP BY s.name, o.name
ORDER BY s.name, o.name;
