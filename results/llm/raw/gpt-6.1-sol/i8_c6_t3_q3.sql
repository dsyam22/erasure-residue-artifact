-- QUERY
SELECT s.name AS schema_name, o.name AS object_name, o.type_desc,
       m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, o.name;

SELECT entity_name, subentity_name, permission_name
FROM sys.fn_my_permissions(NULL, 'DATABASE')
ORDER BY permission_name;

SELECT s.name AS schema_name, t.name AS table_name,
       t.is_tracked_by_cdc, t.is_replicated, t.is_merge_published,
       t.ledger_type_desc,
       p.index_id, p.partition_number, p.rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id
WHERE p.index_id IN (0, 1);
