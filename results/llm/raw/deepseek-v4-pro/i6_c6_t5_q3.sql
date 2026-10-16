-- QUERY
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    c.name AS column_name
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE s.name = 'dbo'
ORDER BY t.name, i.name, ic.key_ordinal;
