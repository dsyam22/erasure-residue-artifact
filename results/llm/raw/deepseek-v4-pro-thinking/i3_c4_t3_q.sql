SELECT 
    DB_NAME() AS database_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    SERVERPROPERTY('Edition') AS edition,
    SERVERPROPERTY('IsFullTextInstalled') AS full_text_installed;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.history_table_id,
    ht.name AS history_table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type_desc,
    c.is_hidden,
    c.collation_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables ht ON t.history_table_id = ht.object_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM sys.indexes i 
        WHERE i.object_id = v.object_id AND i.index_id = 1
    ) THEN 'Yes' ELSE 'No' END AS has_clustered_index,
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
    tr.is_instead_of_trigger
FROM sys.triggers tr
JOIN sys.tables t ON tr.parent_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name, tr.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.name LIKE '%name%' 
   OR c.name LIKE '%email%' 
   OR c.name LIKE '%phone%' 
   OR c.name LIKE '%customer%' 
   OR c.name LIKE '%member%' 
   OR c.name LIKE '%full%' 
   OR c.name LIKE '%contact%'
ORDER BY s.name, t.name, c.name;
