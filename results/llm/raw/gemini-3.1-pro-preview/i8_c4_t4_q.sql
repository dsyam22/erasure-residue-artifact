SELECT 
    t.name AS table_name,
    s.name AS schema_name,
    t.temporal_type_desc,
    h.name AS history_table_name,
    hs.name AS history_schema_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables h ON t.history_table_id = h.object_id
LEFT JOIN sys.schemas hs ON h.schema_id = hs.schema_id;

SELECT 
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY t.name, c.column_id;
