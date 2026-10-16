SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('U','V','P','FN','IF','TF','TR')
ORDER BY s.name, o.name;

SELECT 
    i.name AS index_name,
    s.name AS schema_name,
    t.name AS table_name,
    i.type_desc,
    i.is_unique,
    i.filter_definition
FROM sys.indexes i
JOIN sys.tables t ON t.object_id = i.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE i.type > 0
ORDER BY s.name, t.name, i.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    dc.definition AS default_definition
FROM sys.default_constraints dc
JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name, c.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    cc.definition AS check_definition
FROM sys.check_constraints cc
JOIN sys.tables t ON t.object_id = cc.parent_object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.columns c ON c.object_id = cc.parent_object_id AND c.column_id = cc.parent_column_id
ORDER BY s.name, t.name, c.name;

SELECT 
    fk.name AS fk_name,
    ps.name AS parent_schema,
    pt.name AS parent_table,
    rs.name AS ref_schema,
    rt.name AS ref_table
FROM sys.foreign_keys fk
JOIN sys.tables pt ON pt.object_id = fk.parent_object_id
JOIN sys.schemas ps ON ps.schema_id = pt.schema_id
JOIN sys.tables rt ON rt.object_id = fk.referenced_object_id
JOIN sys.schemas rs ON rs.schema_id = rt.schema_id
ORDER BY ps.name, pt.name, fk.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT 
    name,
    database_id,
    create_date,
    collation_name,
    compatibility_level,
    is_read_committed_snapshot_on,
    snapshot_isolation_state_desc
FROM sys.databases
WHERE database_id = DB_ID();

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.name LIKE '%name%' 
   OR c.name LIKE '%email%' 
   OR c.name LIKE '%phone%'
   OR c.name LIKE '%customer%'
   OR c.name LIKE '%subject%'
   OR c.name LIKE '%person%'
   OR ty.name IN ('nvarchar','varchar','char','nchar','text','ntext')
ORDER BY s.name, t.name, c.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('nvarchar','varchar','char','nchar','text','ntext','xml')
ORDER BY s.name, t.name, c.name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE m.definition LIKE '%customer%' 
   OR m.definition LIKE '%Subject_0000042%'
   OR m.definition LIKE '%subject42@example.invalid%'
   OR m.definition LIKE '%555-0000042%'
ORDER BY s.name, o.name;

SELECT 
    name,
    type_desc,
    is_disabled,
    create_date,
    modify_date
FROM sys.triggers
ORDER BY name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.name NOT IN ('customer')
ORDER BY s.name, t.name, c.name;
