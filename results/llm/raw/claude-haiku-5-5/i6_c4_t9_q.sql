SELECT 'column' AS finding_type,
       s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       c.name AS column_name,
       t.name AS data_type
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%mobile%'
   OR c.name LIKE '%cell%'
   OR c.name LIKE '%contact%'

UNION ALL

SELECT 'module_definition' AS finding_type,
       s.name,
       o.name,
       o.type_desc,
       NULL,
       NULL
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%phone%'

UNION ALL

SELECT 'user_table' AS finding_type,
       s.name,
       o.name,
       o.type_desc,
       CAST(o.temporal_type AS varchar(10)),
       CAST(p.rows AS varchar(20))
FROM sys.tables o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.partitions p ON p.object_id = o.object_id AND p.index_id IN (0,1)
ORDER BY finding_type, schema_name, object_name, column_name;
