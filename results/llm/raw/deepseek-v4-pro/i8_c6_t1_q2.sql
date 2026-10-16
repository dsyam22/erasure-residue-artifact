-- QUERY
SELECT 
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.system_type_id IN (
    SELECT system_type_id FROM sys.types WHERE name IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text', 'int', 'bigint', 'smallint', 'tinyint')
)
AND c.name NOT IN ('object_id', 'schema_id', 'type', 'name', 'principal_id')
ORDER BY t.name, c.name;
