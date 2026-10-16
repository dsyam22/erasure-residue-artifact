SELECT DB_NAME() AS current_db, @@SERVERNAME AS server_name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.type_desc,
    p.rows AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.partitions p 
    ON p.object_id = t.object_id
   AND p.index_id IN (0, 1)
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    m.definition
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
LEFT JOIN sys.sql_modules m ON m.object_id = v.object_id
ORDER BY s.name, v.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    tr.name AS trigger_name,
    tr.is_disabled,
    m.definition
FROM sys.triggers tr
JOIN sys.tables t ON tr.parent_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.sql_modules m ON m.object_id = tr.object_id
ORDER BY s.name, t.name, tr.name;

SELECT 
    fk.name AS foreign_key_name,
    s1.name AS parent_schema,
    tp.name AS parent_table,
    s2.name AS referenced_schema,
    tr.name AS referenced_table,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys fk
JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
JOIN sys.schemas s1 ON tp.schema_id = s1.schema_id
JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
JOIN sys.schemas s2 ON tr.schema_id = s2.schema_id
ORDER BY s1.name, tp.name, fk.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.name LIKE '%name%'
   OR c.name LIKE '%email%'
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%full%'
ORDER BY s.name, t.name, c.column_id;
