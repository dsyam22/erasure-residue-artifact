-- QUERY
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.system_type_id IN (
    SELECT system_type_id FROM sys.types WHERE name IN ('nvarchar', 'varchar', 'nchar', 'char', 'int', 'bigint', 'smallint', 'tinyint')
)
AND t.name != 'customer'
ORDER BY s.name, t.name, c.column_id;
