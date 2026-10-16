-- QUERY
SELECT 
    t.name AS table_name, 
    s.name AS schema_name,
    t.temporal_type_desc,
    h.name AS history_table_name,
    hs.name AS history_schema_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables h ON t.history_table_id = h.object_id
LEFT JOIN sys.schemas hs ON h.schema_id = hs.schema_id
WHERE t.name IN ('customer', 'member') AND s.name = 'dbo';
