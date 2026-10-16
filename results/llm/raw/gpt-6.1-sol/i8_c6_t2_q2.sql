-- QUERY
SELECT N'database' AS category, name AS object_name,
       recovery_model_desc AS detail
FROM sys.databases
WHERE database_id = DB_ID()
UNION ALL
SELECT N'view', QUOTENAME(s.name) + N'.' + QUOTENAME(v.name),
       OBJECT_DEFINITION(v.object_id)
FROM sys.views AS v
JOIN sys.schemas AS s ON s.schema_id = v.schema_id
UNION ALL
SELECT N'internal_table', QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
       t.internal_type_desc
FROM sys.internal_tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
UNION ALL
SELECT N'fulltext_index', QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + N'.' +
       QUOTENAME(OBJECT_NAME(object_id)), N'fulltext'
FROM sys.fulltext_indexes
UNION ALL
SELECT N'allocation', QUOTENAME(OBJECT_SCHEMA_NAME(p.object_id)) + N'.' +
       QUOTENAME(OBJECT_NAME(p.object_id)),
       CONCAT(a.type_desc, N'; total_pages=', a.total_pages,
              N'; used_pages=', a.used_pages)
FROM sys.partitions AS p
JOIN sys.allocation_units AS a
  ON (a.type IN (1, 3) AND a.container_id = p.hobt_id)
  OR (a.type = 2 AND a.container_id = p.partition_id)
WHERE p.object_id = OBJECT_ID(N'dbo.customer');
