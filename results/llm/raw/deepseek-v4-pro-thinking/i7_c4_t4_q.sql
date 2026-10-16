SELECT 
    DB_NAME() AS database_name,
    SERVERPROPERTY('ServerName') AS server_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    SERVERPROPERTY('Edition') AS edition;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    o.create_date,
    o.modify_date
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('U','V','P','FN','IF','TF','TR','SN')
ORDER BY o.type_desc, s.name, o.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    p.partition_number,
    p.rows
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
ORDER BY s.name, t.name, p.partition_number;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    cc.definition AS computed_definition
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.computed_columns cc ON c.object_id = cc.object_id AND c.column_id = cc.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    m.definition
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
JOIN sys.sql_modules m ON v.object_id = m.object_id
ORDER BY s.name, v.name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('P','FN','IF','TF','TR')
ORDER BY o.type_desc, s.name, o.name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%full_name%'
ORDER BY o.type_desc, s.name, o.name;

SELECT 
    SCHEMA_NAME(fk.parent_object_id) AS fk_schema,
    OBJECT_NAME(fk.parent_object_id) AS fk_table,
    fk.name AS fk_name,
    SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys fk
ORDER BY fk_schema, fk_table, fk.name;

SELECT 
    s.name AS schema_name,
    syn.name AS synonym_name,
    syn.base_object_name
FROM sys.synonyms syn
JOIN sys.schemas s ON syn.schema_id = s.schema_id
ORDER BY s.name, syn.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE c.name LIKE '%customer%'
   OR c.name LIKE '%name%'
   OR c.name LIKE '%email%'
   OR c.name LIKE '%phone%'
ORDER BY s.name, t.name, c.column_id;
