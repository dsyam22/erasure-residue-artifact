SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    h.name AS history_table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables h ON t.history_table_id = h.object_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.type = 'U'
ORDER BY s.name, t.name, c.column_id;
