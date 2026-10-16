SELECT 'column' AS item_type,
       s.name AS schema_name,
       t.name AS table_name,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE c.name LIKE '%phone%' OR c.name LIKE '%tel%' OR c.name LIKE '%mobile%'
   OR c.name LIKE '%msisdn%' OR c.name LIKE '%contact%' OR c.name LIKE '%fax%'

UNION ALL

SELECT 'table', s.name, t.name, NULL, NULL, NULL
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.name LIKE '%customer%' OR t.name LIKE '%cust%' OR t.name LIKE '%contact%'
   OR t.name LIKE '%audit%' OR t.name LIKE '%hist%' OR t.name LIKE '%log%'
   OR t.name LIKE '%backup%' OR t.name LIKE '%stag%' OR t.name LIKE '%bak%'
   OR t.temporal_type > 0 OR t.is_tracked_by_cdc = 1

UNION ALL

SELECT 'string_column', s.name, t.name, c.name, TYPE_NAME(c.user_type_id), c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar','text','ntext','xml')
  AND s.name = 'dbo'

UNION ALL

SELECT 'object_definition', s.name, o.name, o.type_desc, NULL, NULL
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%phone%'

ORDER BY item_type, schema_name, table_name, column_name;
